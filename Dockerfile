FROM continuumio/miniconda3
# Use bash instead of sh
SHELL ["/bin/bash", "-c"]
# Install sudo and git
RUN apt-get update && apt-get -y install sudo git-core
# Copy env file
ADD environment.yml environment.yml
# Install conda packages
RUN conda env update -n base --file environment.yml
# Switch to non-root user
RUN useradd --create-home -s /bin/bash jupyter && adduser jupyter sudo
WORKDIR /home/jupyter
USER jupyter
# Add notebook config
ADD jupyter_notebook_config.py notebook_config.py
