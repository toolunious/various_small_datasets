# various_small_datasets

Code for various small datasets where data does not change very often 

# Requirements

    Python >= 3.5

# Preparation

    python3 -m venv venv
    source venv/bin/activate
    pip install -r src/requirements.txt
    
    docker-compose up -d database

# Migrate Django catalog model

    cd src
    python manage.py migrate

# Bedrijfsinvesteringszone (BIZ)

Import data with :

    src/biz/import/import.sh

# Tram & Metro (TRM)

Import data with :
 
    src/trm/import/import.sh

# Handboek Inrichting Openbare Ruimte (HIOR)

Import data with :

    src/hior/import/import.sh

# Import JSON data for catalog (description of BIZ dataset)

    cd src 
    python manage.py import_catalog

# Run the server

    docker-compose up
    
The server can be reached locally at:

    http://localhost:8000

urls to test are

    /status/health
    /status/data
    /vsd/biz/
    /vsd/biz/0/

Filtering on name and geometry field is also supported, although this is not yet  shown in the swagger definition

For example :

    /vsd/biz/?naam=kalverstraat
    /vsd/biz/?geometrie=52.362762,4.907598
    
# Cookbook for new datasets

Create a directory for the new dataset (ds)

    mkdir src/ds
    
Create a directory for the import data for the dataset

    mkdir src/ds/data
    
Put the input data in this directory

Create a directory for the import scripts to process and import the data in the database

    mkdir src/ds/import
    
The basic process consists of:

    Reading the data
    Process and check the data
    Write the results in a .sql file with insert statements
    Call the import and process the sql insert file in a shell script "import.sh"
        Read data and create sql insert file
        Create tables for new data
        Run sql insert on new tables
        Rename existing tables, rename new tables and then remove any old tables
    Use the shared code in src/shared/import to keep the import shell script as small as possible
    
When the import is OK include the dataset in the catalog

    Construct a ds.json in src/various_small_datasets/catalog/data/ds.json
    
    python manage.py import_catalog
    
    python manage.py runserver
    
View your new dataset at localhost:8000/vsd/ds

    