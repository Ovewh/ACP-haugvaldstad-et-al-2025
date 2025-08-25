def variable_translator_lifetime(w):
    variable = w.variable
    vdict = {
        'dulifetime' : ['concdust','depdust'],
        'so4lifetime' : ['concso4','depso4'],
        'concss' : ['concss', 'depss'],
    }
    return vdict[variable]


def variable_translator_MEE(w):
    variable = w.variable
    vdict = {
        'dustMEE' : ['concdust','od550aer'],
        'ssMEE' : ['concss','od550aer'],
        'bcMEE' : ['concbc','od550aer'],
        'so4MEE' : ['concso4','od550aer'],
        'dustMEEabs': ['concdust','abs550aer'],
        'bcMEEabs': ['concbc','abs550aer']
    }
    return vdict[variable]


rule refractive_index_and_absorption:
    input:
        ctrl_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        exp_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        erfs = expand(outdir + 'piClim-2xdust/ERFs/ERF_tables/piClim-2xdust_{model}.csv',
        model = ['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'CNRM-ESM2-1','EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4'])
    wildcard_constraints:
        variable = "SWDirectEff|DirectEff"

    output: 
        absortion_plot = outdir+'figs/AerChemMIP/{variable}_AAOD_refractive_index.png'

    notebook:
        "../notebooks/dust_analysis/optical_properties_absorption.py.ipynb"


rule calculate_lifetime:
    input:
        paths = lambda w: expand(outdir + f"{{experiment}}/derived_variables/{variable_translator_lifetime(w)[0]}/{variable_translator_lifetime(w)[0]}_{{model}}_{{experiment}}_Ayear.nc", 
                   allow_missing=True),
        paths_emissions = lambda w: expand(outdir + f"{{experiment}}/{variable_translator_lifetime(w)[1]}/{variable_translator_lifetime(w)[1]}_{{experiment}}_{{model}}_Ayear.nc",
                allow_missing=True),
        path_area = "workflow/input_data/common_grid.nc"
    output:
        table = outdir + "{experiment}/{variable}/lifetime_{experiment}_{variable}_{model}_Ayear.yaml"
    wildcard_constraints:
        variable = "dulifetime|so4lifetime|pm1lifetime|concss"

    notebook:
        "../notebooks/dust_analysis/lifetime.py.ipynb"

rule make_dust_diag_file:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
        mask = outdir + 'masks/dust_regions.nc',
        burden_exp = outdir + '{experiment}/derived_variables/concdust/concdust_{model}_{experiment}_Ayear.nc',
        universial_area_mask = 'workflow/input_data/common_grid.nc', 
        model_area_mask = 'workflow/input_data/gridarea_{model}.nc'
    output:
        dust_diag_exp = outdir + 'dust_diag_files/dust_diag_{model}_{experiment}.nc',
    
    wildcard_constraints:
        experiment = 'piClim-2xdust|piClim-control'
    
    notebook:
        "../notebooks/dust_analysis/make_dust_diag_file.py.ipynb"

rule make_dust_cloud_diag_file_IPSL:
    input: 
        catalog = ancient(rules.build_catalogues.output.json),
        mask = outdir + 'masks/dust_regions.nc',
        universial_area_mask = 'workflow/input_data/common_grid.nc', 
        model_area_mask = 'workflow/input_data/gridarea_IPSL-CM6A-LR-INCA.nc'
    output:
        dust_cloud_diag_exp = outdir + 'dust_diag_files/dust_cloud_diag_IPSL-CM6A-LR-INCA_{experiment}.nc',
    wildcard_constraints:
        experiment = 'piClim-2xdust|piClim-control'

    conda:
        "geocat"

    notebook:
        "../notebooks/dust_analysis/make_dust_cloud_diag_file.py.ipynb"

rule make_dust_cloud_diag_file_EC_EARTH:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
        mask = outdir + 'masks/dust_regions.nc',
        cdncvi = outdir + '{experiment}/derived_variables/cdncvi/cdncvi_EC-Earth3-AerChem_{experiment}_Ayear.nc',
        universial_area_mask = 'workflow/input_data/common_grid.nc', 
        model_area_mask = 'workflow/input_data/gridarea_EC-Earth3-AerChem.nc',
        clfractions = expand(outdir + '{experiment}/derived_variables/{clfrac}/{clfrac}_EC-Earth3-AerChem_{experiment}_Ayear.nc',
                            clfrac=['clhigh','clmiddle','cllow'], allow_missing=True)
    output:
        dust_cloud_diag_exp = outdir + 'dust_diag_files/dust_cloud_diag_EC-Earth3-AerChem_{experiment}.nc',

    wildcard_constraints:
        experiment = 'piClim-2xdust|piClim-control'

    conda:
        "geocat"

    notebook:
        "../notebooks/dust_analysis/make_dust_cloud_diag_file.py.ipynb"
        

rule make_dust_cloud_diag_file:
    input: 
        catalog = ancient(rules.build_catalogues.output.json),
        mask = outdir + 'masks/dust_regions.nc',
        cdncvi = outdir + '{experiment}/derived_variables/cdncvi/cdncvi_{model}_{experiment}_Ayear.nc',
        universial_area_mask = 'workflow/input_data/common_grid.nc', 
        model_area_mask = 'workflow/input_data/gridarea_{model}.nc'
    output:
        dust_cloud_diag_exp = outdir + 'dust_diag_files/dust_cloud_diag_{model}_{experiment}.nc',
    wildcard_constraints:
        experiment = 'piClim-2xdust|piClim-control',
        model="(?!IPSL-CM6A-LR-INCA|EC-Earth3-AerChem).*"
    conda:
        "geocat"

    notebook:
        "../notebooks/dust_analysis/make_dust_cloud_diag_file.py.ipynb"

rule calc_dust_regional_erf_table:
    input:
        catalog = ancient(rules.build_catalogues.output.json),
        data_tracker = ancient('config/.data_trackers/piClim-2xdust_{model}_CMIP6.yaml'),
        mask = outdir + 'masks/dust_regions.nc'
    output:
        outpath_masked = outdir + 'piClim-2xdust/ERFs/ERF_tables/dusty/piClim-2xdust_{model}.csv',
        outpath_unmasked = outdir + 'piClim-2xdust/ERFs/ERF_tables/nodusty/piClim-2xdust_{model}.csv',
        outpath_all = outdir + 'piClim-2xdust/ERFs/ERF_tables/all/piClim-2xdust_{model}.csv'
    threads: 2

    log:
        "logs/erf_tables/{model}_piClim-2xdust_regional.log"
    notebook:
        "../notebooks/forcing_calculations/calc_global_regional_erf.py.ipynb"

rule plot_dust_diagnostic_table:
    input:
        ctrl_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        exp_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        mask = outdir + 'masks/dust_regions.nc',
    output:    
        outpath = outdir + 'figs/AerChemMIP/dust_diagnostic_table.pdf'

    notebook:
        "../notebooks/dust_analysis/dust_diagnostic_table.py.ipynb"

rule plot_dust_emissions_and_burden_change:
    input:
        ctrl_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        exp_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),

        universial_area_mask = 'workflow/input_data/common_grid.nc', 
        model_area_mask = expand('workflow/input_data/gridarea_{model}.nc', 
                            model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 
                                    'GISS-E2-1-G', 'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA',
                                    'GFDL-ESM4', 'CNRM-ESM2-1']),
    output:
        outpath = outdir +'figs/ACP_paper/fig1_dust_emissions_and_burden_change.png'

    conda:
        "dustysnake"
    notebook:
        "../notebooks/dust_analysis/dust_emissions_and_burden_change.py.ipynb"


rule plot_cloud_diagnostic_table:
    input:
        ctrl_data = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        exp_data = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        mask = outdir + 'masks/dust_regions.nc',
    output:    
        outpath = outdir + 'figs/AerChemMIP/dust_cloud_diagnostic_table.pdf'

    conda:
        "dustysnake"

    notebook:
        "../notebooks/dust_analysis/dust_cloud_diagnostic_table.py.ipynb"


rule arc_precip_scatter_plot:
    input:
        cld_ctrl_data = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        cld_exp_data = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),

        diag_ctrl_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        diag_exp_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),

    output:
        outpath = outdir + 'figs/AerChemMIP/arc_precip_scatter_plot.pdf'
    conda:
        "dustysnake"

    notebook:
        "../notebooks/dust_analysis/arc_precip_scatter_plot.py.ipynb"

rule dust_interest_region_diagnostics:
    input:
        ctrl_clddiag = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        exp_clddiag = expand(outdir + 'dust_diag_files/dust_cloud_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        ctrl_ddiag = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        exp_ddiag = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        forcing_tables = expand(outdir + 'piClim-2xdust/ERFs/ERF_regional_tables/piClim-2xdust_{model}_regional.csv',
        model = ['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'CNRM-ESM2-1','EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4'])
    output:
        outpath = outdir + 'figs/AerChemMIP/dust_interest_region_diagnostics.pdf'
    notebook:
        "../notebooks/dust_analysis/dust_interest_region_diagnostics.py.ipynb"


rule plot_ustar_change:
    input:
        ctrl_ustar = expand(outdir + 'piClim-control/derived_variables/ustar/ustar_{model}_piClim-control_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem','CNRM-ESM2-1',
                        'UKESM1-0-LL','GISS-E2-1-G','GFDL-ESM4', 'IPSL-CM6A-LR-INCA','MIROC6']),
        exp_ustar = expand(outdir + 'piClim-2xdust/derived_variables/ustar/ustar_{model}_piClim-2xdust_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem','CNRM-ESM2-1',
                        'UKESM1-0-LL','GISS-E2-1-G','GFDL-ESM4','IPSL-CM6A-LR-INCA','MIROC6'])

    output:
        outpath = outdir+'figs/AerChemMIP/change_friction_velocity.png'
    
    conda:
        "dustysnake"


    notebook:
        "../notebooks/dust_analysis/change_in_friction_velocity.py.ipynb"
    

rule plot_total_dust_ERF_figure:
    input:
        gridded_ERF = expand(outdir + 'piClim-2xdust/ERFs/ERFt/ERFt_piClim-2xdust_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        dust_forcing_table = expand(outdir + 'piClim-2xdust/ERFs/ERF_tables/piClim-2xdust_{model}.csv',
                model = ['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'CNRM-ESM2-1','EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4']), 
        dust_diag_table = outdir +'tables/AerChemMIP/dust_abs_diagnostic_table.csv',
        dust_diag_table_rel = outdir +'tables/AerChemMIP/dust_rel_diagnostic_table.csv',
        common_grid = 'workflow/input_data/common_grid.nc'
    output:
        outpath = outdir + 'figs/AerChemMIP/total_dust_ERF_figure.png'
    notebook:
        "../notebooks/dust_analysis/total_dust_ERF_figure.py.ipynb"
    

rule cloud_ice_response_to_dust_perturbation:
    input:
        ctrl_data = expand(outdir + 'piClim-control/cli/cli_piClim-control_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        exp_data = expand(outdir + 'piClim-2xdust/cli/cli_piClim-2xdust_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'MIROC6', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1'])
    output:
        outdir+'figs/AerChemMIP/cloud_ice_change.png'

    notebook:
        "../notebooks/dust_analysis/cloud_ice_change_analysis.py.ipynb"

    
rule plot_surface_toa_albedo:
    input: 
        rsdt = expand(outdir + '{exp}/rsdt/rsdt_{exp}_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem',
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1'],
                     allow_missing=True),
        rsutcsaf = expand(outdir + '{exp}/rsutcsaf/rsutcsaf_{exp}_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem',
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1'], 
                         allow_missing=True),
    output:
        outdir+'figs/AerChemMIP/model_surface_toa_albedo_{exp}.png'
    notebook:
        "../notebooks/dust_analysis/model_albedo_intercomparison.py.ipynb"


rule plot_surface_albedo:
    input: 
        rsds = expand(outdir + '{exp}/rsds/rsds_{exp}_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G','MIROC6',
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1'],
                     allow_missing=True),
        rsus = expand(outdir + '{exp}/rsus/rsus_{exp}_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G','MIROC6',
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1'], 
                         allow_missing=True),
    output:
        outdir+'figs/AerChemMIP/model_surface_albedo_{exp}.png'
    notebook:
        "../notebooks/dust_analysis/model_albedo_intercomparison.py.ipynb"


rule scatter_plot_albedo_forcing_efficiency:
    input:
        rsds = expand(outdir + 'piClim-2xdust/rsds/rsds_piClim-2xdust_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem',
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        rsus = expand(outdir + 'piClim-2xdust/rsus/rsus_piClim-2xdust_{model}_Ayear.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        ctrl_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-control.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4','CNRM-ESM2-1']),
        exp_data = expand(outdir + 'dust_diag_files/dust_diag_{model}_piClim-2xdust.nc',
                model=['NorESM2-LM', 'MPI-ESM-1-2-HAM', 'EC-Earth3-AerChem', 'GISS-E2-1-G',
                        'UKESM1-0-LL', 'IPSL-CM6A-LR-INCA', 'GFDL-ESM4', 'CNRM-ESM2-1']),
        paths=expand(outdir+'piClim-2xdust/ERFs/{vName}/{vName}_piClim-2xdust_{model}_Ayear.nc',
            model=['MPI-ESM-1-2-HAM','EC-Earth3-AerChem','CNRM-ESM2-1','NorESM2-LM','UKESM1-0-LL','GFDL-ESM4','IPSL-CM6A-LR-INCA',
            ], allow_missing=True)
    wildcard_constraints:
            vName = 'SWDirectEff|LWDirectEff|DirectEff'
    output:
            outpath= outdir+'figs/AerChemMIP/{vName}_piClim-2xdust_AerChemMIP_albedo-forcing_relationship.png'
    notebook:
            "../notebooks/dust_analysis/albedo_direct_forcing_relationship.py.ipynb"


    

