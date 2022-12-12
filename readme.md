# CKAN TIB project - adopted for the STREAM project

## Docker
All the required information to setup the project can be found [here](docker/readme.md).

## Plugins
The plugins folder should contain all the plugins used in the project as git submodules.
See .gitmodules for the URLs and the readme for [details](Plugins/readme.md).


## Notes

In order to retrieve metadata as DCAT from data repositories the sources have to be set under the /harvest path in the browser.
Then the aggregation has to be started manually per source in the same GUI.

Some CKAN extensions still are using Python 2.7 or similar which creates log errors and makes part of the application less secure.
This issue should be resolved in a successor of this project.

The current version of the Leibniz Data Manager is not public and a merge of it into this repository will be quite cumbersome.
Later work should fork the LDM and include the extensions there.
