FROM fedora:latest AS Source
COPY ./builder.sh /
RUN /usr/bin/env bash builder.sh \
	tzdata busybox

FROM scratch
COPY --from=Source /tmp/dist /
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/xbin
CMD /bin/sh
