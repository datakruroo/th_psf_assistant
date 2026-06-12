FROM nikolaik/python-nodejs:python3.11-nodejs20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        fontconfig \
        fonts-thai-tlwg \
        pandoc \
        texlive-fonts-recommended \
        texlive-latex-extra \
        texlive-latex-recommended \
        texlive-xetex \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
