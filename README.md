# Diversity Data Explorer

# What was this project about?
This [CorrelAid](https://correlaid.org) #Data4Good project was concerned with a classic as well as not generally solved problem: A large N survey with many variables. In the case of our partner organization this meant 100-400 survey items (incl. multiple-choice questions) as well as ~30 individual socio-demographic attributes. These attributes were further be combined to intersectional profiles. Since our partner organization does a lot of group analyses based on the aforementioned variables and profiles, it was important to be able to quickly identify which hypotheses hold and what to focus on for deeper-going analysis from up to 400 * 30 inter-group comparisons.

Hence, the goal of this project was to find ways to break down the complexity and volume of the data to generate outputs that improve the “the search for critical needles in the hay stack” experience of the research team. 

1. automate the creation of outputs such as graphs, cross-tabulations, descriptive statistics that make it faster to get an overview over a dataset, especially the intersectional profiles and how they interact with other variables.
2. create a prioritized list of potentially interesting relationships between variables, especially the intersectional profiles and other variables. This will help researchers prioritize their “manual exploratory data analysis” and support the generation of interesting hypotheses. 
3. find a way to wrap the results in a way that makes it easy to navigate and deploy them, e.g. using platforms like Netlify. 

To reach those goals, the project team built a prototype for a [quarto website](https://quarto.org/docs/websites/) with different components that address the different goals.

# Screenshots
![Screenshot 2023-03-23 at 13-31-24 Home](https://user-images.githubusercontent.com/13187448/227226321-3ceebfb6-10a9-446f-bbc9-70276b7d5adc.png)


![Screenshot 2023-03-23 at 13-28-46 EDA Tool - Visual Analysis Tool](https://user-images.githubusercontent.com/13187448/227226298-cbe15d6a-12a6-4cfd-ad0d-1bf40501c633.png)

![Screenshot 2023-03-23 at 13-29-27 EDA Tool - Visual Analysis Tool](https://user-images.githubusercontent.com/13187448/227226309-ad384652-7eff-4840-8a41-8add9301154f.png)

Screenshots of other parts of the tool cannot be shared due to copyright claims of our partner organization.

# Contributors

Unfortunately, we had to republish the repository without the old commit history, making the numerous contributions from the project team invisible. Here's the list of people who worked on this project and their contributions:

- [@KatBoe](https://github.com/KatBoe): general layout and design, analysis page, visualizations and color schemes
- [@ypislon](https://github.com/ypislon): javascript expertise, analysis page, various fixes and housekeeping
- [@lboel](https://github.com/lboel): Visualizations & UX, optional filter in analysis page, introduction of plotly, code quality
- [@Torben-Stein](https://github.com/Torben-Stein): Statistical Highlights page
- [@friep](https://github.com/friep): survey metadata page, housekeeping, compression backend optimizations
- [@TanjaMB](https://github.com/TanjaMB) & [@SHatzenbuehler](https://github.com/SHatzenbuehler): important early conceptual UX work
- [@lisallreiber](https://github.com/lisallreiber): tech support for database and schema questions


# Prerequisites

## Database access 

Running this project requires credentials for the supabase containing the synthetic data that was set up by [@LisaLLReiber](https://github.com/Lisallreiber) for the Diversity Data Hackathon. Credentials were shared with the CorrelAid project team by [@friep](https://github.com/friep). 

You can use the `usethis` package
or copy the existing `.Renviron.example` file and rename it to `.Renviron`.

```
# get current project
usethis::proj_get()
# set up passwords in .Renviron
usethis::edit_r_environ()
```

The `.Renviron` file should look something like this: 

```
# logins for supabase
COOLIFY_HOST='your-supabase-url' 
COOLIFY_PORT='5432'
COOLIFY_USER='postgres'
COOLIFY_PASSWORD='your-supabase-pw'
COOLIFY_DB='defaultdb'
```

Reload the project or the R session to update the environment variables (Session -> Restart R Session or `.rs.restartR()` or `renv::activate()`).

## Helper data files
Due to copyright claims of our partner organization, we had to refactor some recoding such that answer options were not contained in the code but in additional `csv` "mapping" files to be stored in the `data/helper` subdirectory. Those files are needed in: 

- `eda/statistical_highlights.qmd`
- `R/01_exploratory_nesting.R`

Please contact CorrelAid (info [at] correlaid [dot] org) if you are interested in this. However, as we are not the organization with the copyrights, we can only refer you to our partner organization. 

# Setup

1. **install quarto**: Install quarto by following the instructions [here](https://quarto.org/docs/get-started/).
2. **preprocess data**

Run the following scripts:


```r
source(here::here("R", "00-get-data-from-db.R"))
source(here::here("R", "01_exploratory_nesting.R"))
```

This will take a while (ca. 5min). 

3. **Render the website** to HTML files. 

```
quarto render 
```

Rendering options can be configured in `_quarto.yml`.


# Developer information

## Developer workflow
1. If you're starting out new, repeat steps 1 and 2 from setup above.

2. **Start the project**: open a terminal in RStudio (Tools -> Terminal -> New Terminal) or VSCode.
In your terminal (not the R console!), run: 

```
quarto preview
```

The preview reloads every time when you make a change in the `qmd` files. 

3. Open `http://localhost:7654/`. 


## `renv`: Package management
[`renv`](https://rstudio.github.io/renv/articles/renv.html) brings project-local R dependency management to our project. `renv` uses a lockfile (`renv.lock`) to capture the state of your library at some point in time.
Based on `renv.lock`, RStudio should automatically recognize that it's being needed, thereby downloading and installing the appropriate version of `renv` into the project library. After this has completed, you can then use `renv::restore()` to restore the project library locally on your machine.
When new packages are used, `install.packages()` does not install packages globally, it does in an environment only used for our project. You can find this library in `renv/library` (but it should not be necessary to look at it).
If `renv` fails, you will be presented something in the like of when you first start R after cloning the repo:

```
renv::restore()
This project has not yet been activated. Activating this project will ensure the project library is used during restore. Please see ?renv::activate for more details. Would you like to activate this project before restore? [Y/n]:
```

Follow along with `Y`  and `renv::restore()` will do its work downloading and installing all dependencies.
`renv` uses a local `.Rprofile` and `renv/activate.R` script to handle our project dependencies.

### Adding a new package
If you need to add a new package, you can install it as usual (`install.packages` etc.).
Then, to add your package to the `renv.lock`:

```
renv::snapshot()
```
and commit and push your `renv.lock`.

Other team members can then run `renv::restore()` to install the added package(s) on their laptop.



## Adaptation to new data
In general, most pages would work for different datasets as well. 

However, to adapt this project to new data, quite many adapatations would be needed as the data from our project partner was preprocessed in a very specific way (long format, in a database etc).

If you are interested in this project, please reach out to [projects@correlaid.org](mailto:projects@correlaid.org) so that we can discuss a follow-up project. 

## Deployment options

To deploy the website, you can render the website first and deploy it yourself or use CI/CD pipelines to run either the analysis, the rendering or the deployment (or all of the previous steps) automated.

Currently, the project is configured to render the project in html format with embedded js and css (see `_quarto.yml`, for additional options [refer to the quarto docs](https://quarto.org/docs/reference/formats/html.html#rendering)). This way, the website can be used locally without a webserver (just open the index.html in the browser) or deployed as a static site, e.g. by uploading it to a web server or using Github/Gitlab Pages.

### Github

To host the website on Github, you can refer to the [quarto docs](https://quarto.org/docs/publishing/github-pages.html). The repository is currently configured to be hosted on Gitlab pages: To publish the project, you need to render the website, commit the rendered files and [point the Github repository](https://quarto.org/docs/publishing/github-pages.html) to the folder with the rendered files.

If you want to use Github Actions to automate the render and deployment process (CI and CD), you can (yet again) [refer to the quarto docs](https://quarto.org/docs/publishing/github-pages.html#github-action) about setting up a quarto project and Github Actions.

For both cases, all capabilities of [Github pages](https://docs.github.com/en/pages) can be used.

### Gitlab

To host the website on Gitlab, you have the same options as before: Hosting the static site or using the CI/CD pipelines supported on Gitlab. For both options, the [pipelines](https://docs.gitlab.com/ee/user/admin_area/settings/continuous_integration.html) and [Pages](https://docs.gitlab.com/ee/administration/pages/#gitlab-pages-administration) need to be enabled for the respective instance.

To host the static site, render the files with the current configuration and set up a basic [Gitlab pipeline](https://docs.gitlab.com/ee/ci/introduction/). You can use the [plain html template](https://gitlab.com/pages/plain-html) for Pages and push the rendered files into the repository.

To use the CI/CD pipelines to render the page, you need to adjust the rendering and think about what steps you want to perform in the pipeline. The [quarto docs about Github pages](https://quarto.org/docs/publishing/github-pages.html#executing-code) explain the different approaches and respective steps needed.

### Alternative services

Alternatively, you can use [Quarto Pub](https://quarto.org/docs/publishing/quarto-pub.html) to publish the site publicly from your local machine. The service is free and easy-to-use.

Other alternatives are described in the [quarto docs](https://quarto.org/docs/publishing/).

# Limitations

- **Reproducibility**: Due to copyright claims of our partner organization, the synthetic data that we worked with for this project cannot be shared as part of this repository. Hence, it is not possible to run this project locally. If you are interested in the dahsboard, please contact [projects@correlaid.org](mailto:projects@correlaid.org) so that we can explore options for a follow up project.
- **Code quality**: Code quality - especially of some of the OJS code - is not optimal. 
- **Uncertainty re correctness of analyses**: The data we worked with was quite complex. It'd be good to reproduce analyses with a smaller, less complex dataset as well as do unit tests.  
- **Multi-language support**: Support for multiple languages is only built-in for the metadata page. 

# Partner organization

This project was conducted in collaboration with the [Vielfalt entscheidet](https://citizensforeurope.org/advocating_for_inclusion_page/) project of Citizens For Europe gUG. 
