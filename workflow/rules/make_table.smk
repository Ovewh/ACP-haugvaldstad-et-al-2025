
    
rule text_diagnostic_table:
    input: 
        ctrl_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        exp_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        mask = outdir + 'masks/dust_regions.nc',

    output:
        outpath=outdir+'tables/AerChemMIP/dust_abs_diagnostic_table.csv',
        relpath=outdir+'tables/AerChemMIP/dust_rel_diagnostic_table.csv',
        ctrlpath=outdir+'tables/AerChemMIP/dust_ctrl_diagnostic_table.csv'
    notebook:
        "../notebooks/dust_analysis/dust_diagnostic_table.py.ipynb"        


rule plot_radiative_effect:
    input:
        forcing_tables = expand(outdir + 'piClim-2xdust/ERFs/ERF_tables/piClim-2xdust_{model}.csv',
        model = ['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'CNRM-ESM2-1','EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4']),
        diag_tables = rules.text_diagnostic_table.output

    output:
        outdir+'figs/AerChemMIP/dust_direct_radiative_effect.png'
    notebook:
        "../notebooks/dust_analysis/dust_direct_effective_radiative_effect_plot.py.ipynb"

rule plot_direct_forcing_and_diagnostics_combined:
    input:
        mask = outdir + 'masks/dust_regions.nc',
        forcing_tables = expand(outdir + 'piClim-2xdust/ERFs/ERF_tables/piClim-2xdust_{model}.csv',
        model = ['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'CNRM-ESM2-1','EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4']),
        diag_tables = rules.text_diagnostic_table.output,
    output:    
        outpath = outdir + 'figs/AerChemMIP/merged_directEffect_and_diagnostics.png'
    notebook: 
        "../notebooks/dust_analysis/combined_efficiency_and_diagnostics.py.ipynb"


rule plot_cloud_forcing_and_diagnostics_combined:
    input:
        mask = outdir + 'masks/dust_regions.nc',
        forcing_tables = expand(outdir + 'piClim-2xdust/ERFs/ERF_tables/piClim-2xdust_{model}.csv',
        model = ['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'CNRM-ESM2-1','EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4']),
        ctrl_data = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        exp_data = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
    output:    
        outpath = outdir + 'figs/AerChemMIP/merged_cloudEffect_and_diagnostics.png'
    notebook:
        "../notebooks/dust_analysis/combined_cloudRadiativeEffects_and_diagnostics.py.ipynb"

rule plot_forcing_decomposition_cacti:
    input:
        expand(outdir + 'piClim-2xdust/ERFs/ERF_tables/piClim-2xdust_{model}.csv',
        model = ['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'CNRM-ESM2-1','EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4'])

    output:
        directory(outdir+'figs/AerChemMIP/ERFfigures/')
    notebook:
        "../notebooks/dust_analysis/forcing_plot.py.ipynb"