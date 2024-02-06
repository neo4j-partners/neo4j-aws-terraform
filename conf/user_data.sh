#!/bin/bash -xe
sleep 30

# Upgrade to the latest Amazon Linux 2023
dnf upgrade -y --releasever=2023.2.20231113
update-motd

# Forward all logs to the console
exec > >(tee /var/log/user-data.log | logger -t user-data-extra -s 2>/dev/console) 2>&1

# Configure Cloudwatch agent
pushd /tmp
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
popd

# Setup the prometheus scraping for neo4j
aws ssm get-parameter --name ${ssm_prometheus} --output=text --query "Parameter.Value" >/opt/aws/amazon-cloudwatch-agent/etc/prometheus.yml

# Use cloudwatch config from SSM
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c ssm:${ssm_cloudwatch_config} -s

# 1 - Variable Setting and Test
NEO4J_PASSWORD=${neo4j_password}
NEO4J_MAJOR=${neo4j_major_version}
TARGET_REGION=${target_region}
THIS_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PREFIX=${prefix}
APOC_VERSION="" # This will be set based on the Neo4j version
BACKUP_DIR="/home/ec2-user/backups"
BACKUP_BUCKET=${backup_bucket}

function aws_get_private_fqdn {
  aws ec2 describe-instances --output=text --region=$TARGET_REGION --filters Name=tag:Terraform,Values=true --filters Name=tag:Name,Values=$PREFIX-instance --query "Reservations[].Instances[].PrivateDnsName"
}

function aws_get_private_ips {
  aws ec2 describe-instances --output=text --region=$TARGET_REGION --filters Name=tag:Terraform,Values=true --filters Name=tag:Name,Values=$PREFIX-instance --query "Reservations[].Instances[].PrivateIpAddress"
}

FQDN=$(aws_get_private_fqdn)

# 2 - Install Neo4j using yum
echo " - [ Installing Graph Database ] - "
export NEO4J_ACCEPT_LICENSE_AGREEMENT=yes

PACKAGE_VERSION=$(curl --fail http://versions.neo4j-templates.com/target.json | jq -r ".aws[\"$NEO4J_MAJOR\"]" || echo "")
if [[ ! -z $PACKAGE_VERSION && $PACKAGE_VERSION != "null" ]]; then
  echo " - [ Found PACKAGE_VERSION from http://versions.neo4j-templates.com : PACKAGE_VERSION=$PACKAGE_VERSION ] - "
  yum install -y neo4j-enterprise-$PACKAGE_VERSION
  sleep 1
else
  echo '- [ Failed to resolve Neo4j version from http://versions.neo4j-templates.com, using PACKAGE_VERSION=latest ] - '
  yum install -y "neo4j-enterprise"
fi

systemctl enable neo4j
if [[ "$PACKAGE_VERSION" == "latest" ]]; then
  PACKAGE_VERSION=$(/usr/share/neo4j/bin/neo4j --version)
fi

APOC_VERSION="$PACKAGE_VERSION"

# 3 - Extension Config
echo " - [ Configuring extensions and security in neo4j.conf ] - "
sed -i s/#dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*/dbms.security.procedures.unrestricted=apoc.*/g /etc/neo4j/neo4j.conf
echo "dbms.security.http_auth_allowlist=/,/browser.*" >>/etc/neo4j/neo4j.conf
echo "dbms.security.procedures.allowlist=apoc.*" >>/etc/neo4j/neo4j.conf

# 4 - Neo4j Main Configuration
echo " - [ Neo4j Main (Network & Cluster Configuration ] - "
THIS_PRIVATE_IP="$(hostname -i | awk '{print $NF}')"
sed -i s/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g /etc/neo4j/neo4j.conf
sed -i s/#server.default_advertised_address=localhost/server.default_advertised_address="$FQDN"/g /etc/neo4j/neo4j.conf
sed -i s/#server.discovery.advertised_address=:5000/server.discovery.advertised_address="$THIS_PRIVATE_IP":5000/g /etc/neo4j/neo4j.conf
sed -i s/#server.cluster.advertised_address=:6000/server.cluster.advertised_address="$THIS_PRIVATE_IP":6000/g /etc/neo4j/neo4j.conf
sed -i s/#server.cluster.raft.advertised_address=:7000/server.cluster.raft.advertised_address="$THIS_PRIVATE_IP":7000/g /etc/neo4j/neo4j.conf
sed -i s/#server.routing.advertised_address=:7688/server.routing.advertised_address="$THIS_PRIVATE_IP":7688/g /etc/neo4j/neo4j.conf
sed -i s/#server.discovery.listen_address=:5000/server.discovery.listen_address="$THIS_PRIVATE_IP":5000/g /etc/neo4j/neo4j.conf
sed -i s/#server.routing.listen_address=0.0.0.0:7688/server.routing.listen_address="$THIS_PRIVATE_IP":7688/g /etc/neo4j/neo4j.conf
sed -i s/#server.cluster.listen_address=:6000/server.cluster.listen_address="$THIS_PRIVATE_IP":6000/g /etc/neo4j/neo4j.conf
sed -i s/#server.cluster.raft.listen_address=:7000/server.cluster.raft.listen_address="$THIS_PRIVATE_IP":7000/g /etc/neo4j/neo4j.conf
sed -i s/#server.bolt.listen_address=:7687/server.bolt.listen_address="$THIS_PRIVATE_IP":7687/g /etc/neo4j/neo4j.conf
sed -i s/#server.bolt.advertised_address=:7687/server.bolt.advertised_address="$THIS_PRIVATE_IP":7687/g /etc/neo4j/neo4j.conf

neo4j-admin server memory-recommendation >>/etc/neo4j/neo4j.conf

echo "server.metrics.enabled=true" >>/etc/neo4j/neo4j.conf
echo "server.metrics.jmx.enabled=true" >>/etc/neo4j/neo4j.conf
echo "server.metrics.prefix=neo4j" >>/etc/neo4j/neo4j.conf
echo "server.metrics.filter=*" >>/etc/neo4j/neo4j.conf
echo "server.metrics.csv.interval=5s" >>/etc/neo4j/neo4j.conf
echo "dbms.routing.default_router=SERVER" >>/etc/neo4j/neo4j.conf
echo "db.logs.query.enabled=INFO" >>/etc/neo4j/neo4j.conf
echo "db.logs.query.threshold=2s" >>/etc/neo4j/neo4j.conf
echo "server.metrics.prometheus.enabled=true" >>/etc/neo4j/neo4j.conf
echo "server.metrics.prometheus.endpoint=localhost:2004" >>/etc/neo4j/neo4j.conf

# Install UUID and setup indexes and constraints
echo " - [ Configuring APOC and indexes/constraints ] - "
wget -q https://github.com/neo4j/apoc/releases/download/$APOC_VERSION/apoc-$APOC_VERSION-core.jar -P /var/lib/neo4j/plugins
wget -q https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/$APOC_VERSION/apoc-$APOC_VERSION-extended.jar -P /var/lib/neo4j/plugins
chown neo4j:neo4j /var/lib/neo4j/plugins/apoc-$APOC_VERSION-extended.jar
chmod 755 /var/lib/neo4j/plugins/apoc-$APOC_VERSION-extended.jar
touch /etc/neo4j/apoc.conf
chown neo4j:neo4j /etc/neo4j/apoc.conf
echo 'apoc.uuid.enabled=true' >>/etc/neo4j/apoc.conf
echo 'apoc.uuid.refresh=10' >>/etc/neo4j/apoc.conf
echo 'apoc.import.file.use_neo4j_config=true' >>/etc/neo4j/apoc.conf
echo 'apoc.import.file.enabled=true' >>/etc/neo4j/apoc.conf
echo 'apoc.export.file.enabled=true' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.0=CREATE CONSTRAINT asset_identifier IF NOT EXISTS FOR (n:Asset) REQUIRE n.identifier IS UNIQUE' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.1=CREATE CONSTRAINT policy_entity_identifier IF NOT EXISTS FOR (n:PolicyEntity) REQUIRE n.identifier IS UNIQUE' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.2=CREATE CONSTRAINT result_entity_identifier IF NOT EXISTS FOR (n:ResultEntity) REQUIRE n.identifier IS UNIQUE' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.3=CREATE CONSTRAINT attribute_identifier IF NOT EXISTS FOR (a:Attribute) REQUIRE a.identifier IS UNIQUE' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.4=CALL apoc.uuid.install("Asset", {uuidProperty: "identifier", addToExistingNodes: false})' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.5=CALL apoc.uuid.install("PolicyEntity", {uuidProperty: "identifier", addToExistingNodes: false})' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.6=CALL apoc.uuid.install("ResultEntity", {uuidProperty: "identifier", addToExistingNodes: false})' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.7=CALL apoc.uuid.install("Attribute", {uuidProperty: "identifier", addToExistingNodes: false})' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.8=CREATE FULLTEXT INDEX search_index IF NOT EXISTS FOR (n:Asset|PolicyEntity|Vulnerability|VulnerablePackage) ON EACH [n.idFromProvider, n.name, n.slug, n.internalName, n.vulnID] OPTIONS {indexConfig: {`fulltext.eventually_consistent`: true}}' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.9=CREATE INDEX iamPermission_name IF NOT EXISTS FOR (n:IAMPermission) ON (n.name)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.10=CREATE INDEX asset_idFromProvider IF NOT EXISTS FOR (n:Asset) ON (n.idFromProvider)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.11=CREATE INDEX control_slug IF NOT EXISTS FOR (c:Control) ON c.slug' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.12=CREATE INDEX procedure_slug IF NOT EXISTS FOR (pr:Procedure) ON pr.slug' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.13=CREATE INDEX awsAsset_package IF NOT EXISTS FOR (n:AWSAsset) ON (n.awsPackage)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.14=CREATE INDEX awsAsset_assetType IF NOT EXISTS FOR (n:AWSAsset) ON (n.awsAssetType)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.15=CREATE INDEX asset_composite IF NOT EXISTS FOR (n:Asset) ON (n.idFromProvider, n.cloudAccountID, n.accountID)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.16=CREATE INDEX finding_idFromProvider IF NOT EXISTS FOR (n:Finding) ON (n.idFromProvider)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.17=CREATE CONSTRAINT person_id IF NOT EXISTS FOR (a:Person) REQUIRE a.personID IS UNIQUE' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.18=CREATE INDEX tagKeyValue IF NOT EXISTS FOR (n:Tag) ON (n.key, n.value)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.16=CREATE INDEX vulnerable_package_hash IF NOT EXISTS FOR (n:VulnerablePackage) ON (n.hash)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.16=CREATE INDEX vulnerable_package_idFromProvider IF NOT EXISTS FOR (n:VulnerablePackage) ON (n.idFromProvider)' >>/etc/neo4j/apoc.conf
# The following indexes should be automatically created by Neo4j
echo 'apoc.initializer.neo4j.19=CREATE LOOKUP INDEX IF NOT EXISTS FOR ()-[r]-() ON EACH type(r)' >>/etc/neo4j/apoc.conf
echo 'apoc.initializer.neo4j.20=CREATE LOOKUP INDEX IF NOT EXISTS FOR (n) ON EACH labels(n)' >>/etc/neo4j/apoc.conf

# Log only ERRORs until https://github.com/neo4j-contrib/neo4j-apoc-procedures/issues/3840 is fixed
sed -i s/level=\"INFO\"/level=\"ERROR\"/g /etc/neo4j/user-logs.xml

# 7 - Start Neo4j
echo " - [ Starting Neo4j ] - "
service neo4j start
neo4j-admin dbms set-initial-password "$NEO4J_PASSWORD"

# Setup neo4j-admin (online) backups
yum install cronie -y
systemctl enable crond.service
systemctl start crond.service
pushd /home/ec2-user
mkdir $BACKUP_DIR
touch backup.sh
echo '#!/bin/bash -xe' >>backup.sh
echo "neo4j-admin database backup --to-path=$BACKUP_DIR --type=full neo4j" >>backup.sh
echo "aws s3 cp --recursive $BACKUP_DIR/ s3://$BACKUP_BUCKET/neo4j" >>backup.sh
echo "rm $BACKUP_DIR/*" >>backup.sh
chmod +x backup.sh
echo "00 22 * * * /home/ec2-user/backup.sh" | crontab -
popd
