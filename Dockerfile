FROM nfcore/base
LABEL authors="Marc Hoeppner" \
      description="Docker image containing all requirements for THIS pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/PIPELINE-VERSION/bin:$PATH

RUN apt-get -y update && apt-get -y install make wget
