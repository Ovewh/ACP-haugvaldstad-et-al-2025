



rule calc_ERF_surf:
    input:
        exp_downwelling_SW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][1],
                                            experiment=w.experiment,freq='Ayear', model=w.model),
        exp_upwelling_SW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][0],
                                        experiment=w.experiment, freq='Ayear',model=w.model),
        exp_upwelling_LW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][2],
                                        experiment=w.experiment, freq='Ayear',model=w.model),
        exp_downwelling_LW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][3],
                                experiment=w.experiment, freq='Ayear',model=w.model),
        ctrl_downwelling_SW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][1],
                        experiment='piClim-control', freq='Ayear',model=w.model),
        ctrl_upwelling_SW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][0],
                        experiment='piClim-control', freq='Ayear',model=w.model),
        ctrl_upwelling_LW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][2],
                        experiment='piClim-control', freq='Ayear',model=w.model),
        ctrl_downwelling_LW = lambda w:expand(rules.get_data_intake.output, variable=VARS[w.vName][3],
                        experiment='piClim-control', freq='Ayear',model=w.model)

    output:
        outpath = outdir + '{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_{freq}.nc'
    
    wildcard_constraints:
        vName = 'ERFsurf|ERFsurfcs'

    log:
        "logs/calc_ERF_surf/{vName}_{model}_{experiment}_{freq}.log"
    
    notebook:
        "../notebooks/forcing_calculations/compute_ERF_surf.py.ipynb"


rule calculate_ERF_TOA:
    input:
        exp_downwelling_SW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][1],
                                            experiment=w.experiment,freq='Ayear', model=w.model),
        exp_upwelling_SW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][0],
                                        experiment=w.experiment, freq='Ayear',model=w.model),
        exp_upwelling_LW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][2],
                                        experiment=w.experiment, freq='Ayear',model=w.model),
        ctrl_downwelling_SW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][1],
                        experiment='piClim-control', freq='Ayear',model=w.model),
        ctrl_upwelling_SW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][0],
                        experiment='piClim-control', freq='Ayear',model=w.model),
        ctrl_upwelling_LW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][2],
                        experiment='piClim-control', freq='Ayear',model=w.model)
    
    output:
        outpath = outdir + '{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_{freq}.nc'
    
    log:
        "logs/calc_ERF_toa/{vName}_{model}_{experiment}_{freq}.log"
    conda:
        "dustysnake"

    wildcard_constraints:
        vName = 'ERFt|ERFtcs|ERFtaf|ERFtcsaf'
    
    notebook:
        "../notebooks/forcing_calculations/compute_ERF_TOA.py.ipynb"



rule calculate_SW_ERF:
    input:
        exp_downwelling_SW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][1],
                                            experiment=w.experiment,freq='Ayear', model=w.model),
        exp_upwelling_SW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][0],
                                        experiment=w.experiment, freq='Ayear',model=w.model),
        ctrl_downwelling_SW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][1],
                        experiment='piClim-control', freq='Ayear',model=w.model),
        ctrl_upwelling_SW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][0],
                        experiment='piClim-control', freq='Ayear',model=w.model),
    
    output:
        outpath = outdir + '{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_{freq}.nc'
    
    wildcard_constraints:
        vName='ERFtsw|ERFtswcs|ERFsurfsw|ERFsurfswcs|ERFtswcsaf|ERFtswaf'
    log:
        "logs/calc_ERF_SW/{vName}_{model}_{experiment}_{freq}.log"  
    notebook:
        "../notebooks/forcing_calculations/compute_ERF_SW.py.ipynb"

rule calculate_ERF_TOA_LW:
    input:
        exp_upwelling_LW = lambda w: expand(rules.get_data_intake.output,variable=VARS[w.vName][0],
                                        experiment=w.experiment, freq='Ayear',model=w.model),
        ctrl_upwelling_LW = lambda w: expand(rules.get_data_intake.output, variable=VARS[w.vName][0],
                        experiment='piClim-control', freq='Ayear',model=w.model)
    output:
        outpath = outdir + '{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_{freq}.nc'
    log:
        "logs/calc_ERF_LW/{vName}_{model}_{experiment}_{freq}.log"  
    wildcard_constraints:
        vName='ERFtlw|ERFtlwaf|ERFtlwcs|ERFtlwcsaf|ERFsurflw'
    conda:
        "dustysnake"


    script:
        "../scripts/compute_ERF_LW_TOA.py"


rule calc_cloud_radiative_effect:
    input:
        ERFaf =  lambda w: outdir + f'{w.experiment}/ERFs/{VARS[w.vName][0]}/{VARS[w.vName][0]}_{w.experiment}_{w.model}_{w.freq}.nc',
        ERFafcs = lambda w: outdir + f'{w.experiment}/ERFs/{VARS[w.vName][1]}/{VARS[w.vName][1]}_{w.experiment}_{w.model}_{w.freq}.nc'
    output:
        outpath= outdir+'{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_{freq}.nc'
    wildcard_constraints:
        vName='CloudEff|SWCloudEff|LWCloudEff'
    
    log:
        "logs/{vName}_{model}_{experiment}_{freq}.log"
    conda:
        "dustysnake"
    script:
        "../scripts/compute_cloud_effect.py"

rule calc_direct_radiative_effect:
    input:
        ERFt =  lambda w:  outdir+ f'{w.experiment}/ERFs/{VARS[w.vName][0]}/{VARS[w.vName][0]}_{w.experiment}_{w.model}_{w.freq}.nc',
        ERFtaf = lambda w: outdir +f'{w.experiment}/ERFs/{VARS[w.vName][1]}/{VARS[w.vName][1]}_{w.experiment}_{w.model}_{w.freq}.nc'
    output:
        outpath=outdir + '{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_{freq}.nc'

    log:
        "logs/rad/{vName}_{model}_{experiment}_{freq}.log"
    conda: 
        "dustysnake"
    wildcard_constraints:
        vName='SWDirectEff|SWDirectEff_cs|LWDirectEff|LWDirectEff_cs|DirectEff'
    notebook:
        "../notebooks/forcing_calculations/compute_direct_radiative_effect.py.ipynb"

rule calc_forcing_efficiency_per_aod:
    input:
        forcing = outdir + '{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_Ayear.nc',
        aod = outdir + '{hist_pert}-{hist_base}/od550aer/od550aer_{model}_delta_{hist_pert}_{hist_base}.nc'
    output:
        outpath = outdir + 'forcing_efficiency/{experiment}/{vName}_{model}_delta_{hist_pert}_{hist_base}.nc' 

    wildcard_constraints:
        vName='ERFt|CloudEff|DirectEff'
    notebook:
        '../notebooks/calc_forcing_efficiency.py.ipynb'

rule calc_absorption:
    input:
        delta_rad_surf = lambda w: outdir + f'{w.experiment}/ERFs/{VARS[w.vName][1]}/{VARS[w.vName][1]}_{w.experiment}_{w.model}_{w.freq}.nc',
        delta_rad_toa = lambda w: outdir + f'{w.experiment}/ERFs/{VARS[w.vName][0]}/{VARS[w.vName][0]}_{w.experiment}_{w.model}_{w.freq}.nc'
    output:
        outpath= outdir+'{experiment}/ERFs/{vName}/{vName}_{experiment}_{model}_{freq}.nc'
    wildcard_constraints:
        vName='atmabsSW|atmabs|atmabsLW'
    log:
        "logs/calc_absorption/{vName}_{model}_{experiment}_{freq}.log"
    run:
        import xarray as xr
        from pyclim_noresm.aerosol_forcing import calc_atm_abs
        import time
        vName_rad_surf = VARS[wildcards.vName][1]
        vName_rad_toa = VARS[wildcards.vName][0]
        delta_rad_toa = xr.open_dataset(input.delta_rad_toa)
        delta_rad_surf = xr.open_dataset(input.delta_rad_surf)
        atm_abs = calc_atm_abs(delta_rad_surf[vName_rad_surf],delta_rad_toa[vName_rad_toa])

        atm_abs = atm_abs.to_dataset(name=wildcards.vName)
        atm_abs.attrs=copy.copy(delta_rad_surf.attrs)
        atm_abs.attrs['title'] = 'Atmospheric absorbtion'
        atm_abs.attrs['history'] = f'@{time.ctime()} Generated by: {__file__} ' + atm_abs.attrs['history']
        atm_abs.attrs['source'] = ', '.join(input) + ', ' + atm_abs.attrs['source']
        atm_abs.attrs['variable_id'] = wildcards.vName
        atm_abs.to_netcdf(output.outpath)