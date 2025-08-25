# Snakemake workflow: CLimate Impact of AeroSOls 

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.3.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions
status](https://github.com/<owner>/<repo>/workflows/Tests/badge.svg?branch=main)](https://github.com/<owner>/<repo>/actions?query=branch%3Amain+workflow%3ATests)


A Snakemake workflow for analysing CMIP6 model output, used for the analysis shown in Haugvaldstad et al 2025. This workflow is designed
work with CMIP6 model data stored in DKRZ data format. 

## Installation

Before you can run the workflow the a conda environment need to be built first:

```
conda env create -f dustysnake -p ./dustysnake
```
Then activate the environment: 

```
conda activate ./dustysnake

``` 

Alternatively the full docker image is archived on [zenodo](https://zenodo.org/records/16942900). 
This docker image should allow to obtain the exact same environment as the one used for the analysis.

## Usage

![dag](dag_t.svg)
*How the different rules are connected inorder to create the final tables.*

The workflow can be configured in the `config/config.yaml` file. Here which
experiment and activities to analyze can be defined. Current version has been
primarily developed for analyzing AerChemMIP type of experiments.  

* Uses the `lookup_*.yaml` files are used to find the  CMIP6 files, to avoid to
  extensive globbing search. To make it faster when working on mounted file
  systems. 

* Extending the workflow can be done trough adding additional rules. Following
  the standard snakemake format.

### Running the workflow:
Default is to run the `all` rule defined in the `Snakefile`:
```
snakemake -j2 
``` 

The `-j` argument specify how many cores the workflow will use. 
  
To print which rules are defined in the workflow use:
```
snakemake -l

all
arc_precip_scatter_plot
build_catalogues
calc_ERF_surf
calc_absorption
calc_cloud_fraction
calc_cloud_radiative_effect
calc_direct_radiative_effect
calc_dust_regional_erf_table
calc_forcing_efficiency_per_aod
calc_global_regional_erf_table
calc_regional_erf_table
calculate_ERF_TOA
calculate_ERF_TOA_LW
calculate_SW_ERF
calculate_lifetime
cloud_ice_response_to_dust_perturbation
column_integrate_cdnc
column_integrate_cdnc_UKESM
column_integrate_cdnc_zarr
derive_column_integrated_load
derive_column_integrated_load_airmass
dust_interest_region_diagnostics
get_data_intake
get_data_intake_zarr
make_available_data_tracker
make_dust_cloud_diag_file
make_dust_cloud_diag_file_EC_EARTH
make_dust_cloud_diag_file_IPSL
make_dust_diag_file
make_local_catalogue
mask_dust_regions
plot_ERFs
plot_albedo_radiative_effect
plot_atmospheric_absorption
plot_ccn_change
plot_change_aaod
plot_change_aod
plot_change_cdncvi
plot_change_clivi
plot_change_clt
plot_change_clwvi
plot_change_concdust
plot_change_concso4
plot_change_lwp
plot_change_prs
plot_change_tas
plot_cl_aerchemmip
plot_cli_aerchemmip
plot_cloud_diagnostic_table
plot_cloud_forcing_and_diagnostics_combined
plot_direct_and_cloud_effect
plot_direct_forcing_and_diagnostics_combined
plot_dust_diagnostic_table
plot_dust_emissions_and_burden_change
plot_emidust
plot_forcing_decomposition_cacti
plot_global_avaraged_ERFs
plot_level_cloud_changes
plot_lwp_aerchemmip
plot_pr_aerchemmip
plot_radiative_effect
plot_surface_albedo
plot_surface_toa_albedo
plot_total_dust_ERF_figure
plot_ustar_change
refractive_index_and_absorption
scatter_plot_albedo_forcing_efficiency
text_diagnostic_table

``` 
The plain all rule will recreate all the figures shown in the original publication. 

## Mounting of CMIP6 storage server
This workflow relies on the having access to the Betzy and Nird storage system.
Most of the CMIP6 data archived in Norway is stored at the Betzy super computer, while the
NorESM output is archived on the NIRD storage server. However it should also be possible
to make the workflow work on any storage systems also as the data is archived
following the DKRZ data format. 