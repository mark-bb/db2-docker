ARG         IMAGE_BASE

FROM        $IMAGE_BASE
MAINTAINER  Mark Barinstein <mark.barinstein@gmail.com>
ARG         INSTALLCMD=/setup/install.sh
ARG         VRMF

COPY        cfg/* /setup/
RUN         --mount=type=bind,source=distrib/db2/$VRMF,target=/tmp/distrib/db2 chmod +x $INSTALLCMD && $INSTALLCMD $VRMF

EXPOSE      50000 
USER        root
WORKDIR     /
ENTRYPOINT  ["/setup/startup.sh"]
