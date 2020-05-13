FROM centos:7
MAINTAINER Shailesh Patel shailesh@aboutobjects.com

RUN yum update -y
RUN yum install -y wget unzip tar 

RUN localedef -c -i en_US -f UTF-8 en_US.utf8
RUN yum reinstall glibc-common -y && \
  localedef -c -i en_US -f UTF-8 en_US.utf8 && \
  echo "LANG=en_US.utf8" > /etc/locale.conf

ENV LANG="en_US.utf8" LC_ALL="en_US.utf8"

RUN rpm -Uvh https://github.com/rabbitmq/erlang-rpm/releases/download/v19.3.6.5/erlang-19.3.6.5-1.el7.centos.x86_64.rpm
RUN yum install -y erlang

RUN rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
RUN yum install -y  https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.7.0/rabbitmq-server-3.7.0-1.el7.noarch.rpm

RUN /usr/sbin/rabbitmq-plugins list <<<'y'
RUN /usr/sbin/rabbitmq-plugins enable --offline rabbitmq_mqtt rabbitmq_stomp rabbitmq_management  rabbitmq_management_agent rabbitmq_federation rabbitmq_federation_management <<<'y'

#CMD /usr/sbin/rabbitmq-server

ADD rabbitmq.config /etc/rabbitmq/
ADD erlang.cookie /var/lib/rabbitmq/.erlang.cookie
ADD startrabbit.sh /opt/rabbit/

RUN chmod u+rw /etc/rabbitmq/rabbitmq.config \
&& chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie \
&& chmod 400 /var/lib/rabbitmq/.erlang.cookie \
&& mkdir -p /opt/rabbit \
&& chmod a+x /opt/rabbit/startrabbit.sh

EXPOSE 5672
EXPOSE 15672
EXPOSE 25672
EXPOSE 4369
EXPOSE 9100
EXPOSE 9101
EXPOSE 9102
EXPOSE 9103
EXPOSE 9104
EXPOSE 9105

CMD LANG="en_US.UTF-8" LC_CTYPE="en_US.UTF-8" LC_ALL="en_US.UTF-8" /opt/rabbit/startrabbit.sh
