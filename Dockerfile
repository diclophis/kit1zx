FROM wkndr:latest

COPY resources/* /var/lib/wkndr/resources/
COPY Wkndrfile /var/lib/wkndr/

RUN ls -lh /var/lib/wkndr/resources

RUN /var/lib/wkndr/iterate-web.sh
