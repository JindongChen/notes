FROM jupyter/datascience-notebook

COPY .gitconfig /home/jovyan/.gitconfig
RUN pip install --upgrade pip \
    && pip install pymysql \
    && pip install openpyxl \
    && pip install lxml \
    && pip install tushare
