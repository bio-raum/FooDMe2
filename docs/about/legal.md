# Legal notes

Please note that we are academics, not lawyers. Our intention with FooDMe2 is to provide a workflow for a specific purpose that may be used in as broad a setting as possible. To this end, we have tried our best to build this pipeline on open-source components as much as possible. However, as you can perhaps imagine, many of the software packages we have integrated into FooDMe2 themselves may incoporate a host of additional dependencies. It is unfortunately not possible for us to fully entangle this web of interdependencies and licenses. If you plan on using FooDMe2 in a commercial setting, we kindly request that you perform your own legal analysis. We include a list of software tools with each pipeline report, as well as a log file in the subfolder `pipeline_info`. A (potentially incomplete) list of (primary) tools can also be found in our [software documentation](software.md).

The pipeline itself, that is the implementation of the logic, as well as the documentation, are of course free to use under the [GPL3 license](license.md)

## Conda licensing

Conda is a package manager that can create isolated environments and install versioned software into it. For this, conda makes use of various channels, or repositories, which provide access to the instructions needed for the installation of packages. 

As of 2024, the Anaconda project has put the so-called "defaults" channels hosted by Anaconda as well as the Anaconda-hosted [distribution](https://www.anaconda.com/download) under [license restrictions](https://www.anaconda.com/legal/terms/terms-of-service#). Briefly, this new license requires organizations with 200 or more employees to pay for a business subscription for continued use of these components.

As FooDMe2 allows the use of conda as one of the means to provision software, we want to remind you to check if your use of conda meets these restrictions. FooDMe2 obtains its various conda packages solely through community-driven channels (e.g. conda-forge, bioconda), although we cannot guarantee that individual packages themselves would not retrieve dependencies from the defaults channels. You may wish to blacklist the official Anaconda repositories in your organization (i.e. on the level if your firewall) to ensure no accidental violations. 

We also recommend that you use alternative conda solvers over the official version from Anaconda, such as [Miniforge](https://github.com/conda-forge/miniforge) and the mamba executable. 
