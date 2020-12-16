
c:.opts.addopt[`;`debug;1b;"debug"];
c:.opts.addopt[c;`datapath;.file.makepath[`:/home/steve;"projects/coronavirus/data"];"data path"];
c:.opts.addopt[c;`regions;`us`states;"valid regions to query"];
parms:.opts.get_opts c;
show parms;

\l /home/steve/kdb/util/graph.q


load_data:{[parms] data:(parms`regions)!get each .file.makepath[parms`datapath] each parms`regions};
load_census_data:{[parms] 
   pop:("SSSSSSI",55#"F";1#csv)0: .file.makepath[parms[`datapath];`censusPopulation.csv];
   pop:.tbl.rename[pop;cols[pop];lower each cols[pop]];
   cp:cols pop;
   pop:(`state,(cp where cp like "popestimate*"),(cp where cp like "death*"))#pop;
   pop}
  
compute_death_rates:{[pop;parms]
   pstk:.tbl.stack[pop;`state;`;`];
   pstks:0!.tbl.split[update year:{"I"$-4#string x}each parmf,qty:?[parmf like "popest*";`population;`deaths] from pstk;`state`year;`qty;`valf];
   dthrate:update deathrate:valf_deaths%valf_population from pstks;
   dthrate};

main:{[parms]
  data:load_data[parms];
  
  tbl:(select date,state,death from data[`states]),select date,state:`us,death from data[`us];
  tbl:select from tbl where not null death;
  tbl:update dailyDeath:deltas death by state from tbl;
  tbl:update dailyDeath7:mavg[7;dailyDeath] by state from tbl;
  
  pop:load_census_data[parms];
  dthrate:compute_death_rates[pop;parms];
  pop:pop lj select annual_deathrate:avg[deathrate] by state from dthrate;
  pop:update pop:popestimate2019 from pop;
  tbl:tbl lj select last pop,last annual_deathrate by state from pop;
  tbl:update ann_covid_deathrate:365*dailyDeath7%pop from tbl;
  -1 "Worst day of covid deaths by state, annualized, and compared with the average death rate for the state";
  show `frac_covid xdesc update frac_covid:ann_covid_deathrate%annual_deathrate from select from tbl where ann_covid_deathrate=(max;ann_covid_deathrate) fby state;
 
  tt:update covid_frac:ann_covid_death%annual_deathrate from update ann_covid_death:dailyDeath*N%365 from select sum[dailyDeath%pop],N:count[i],avg[annual_deathrate] by state from tbl;
  .graph.xyt[tt;();0b;`state`covid_frac;(`title;"Excess Covid Deaths by State";`xsort;0b)];

  .graph.xyt[tbl;"state<>`us,state in `NY`CA`TX`WA`IL`NC";`state;`date`dailyDeath7;`]

  pop_stack:update year:{"I"$-4#string x}'[parmf] from .tbl.stack[pop;`state;`;`]; 
  pop_stack:update parmf:{`$-4_string x}'[parmf] from pop_stack;
  pop_stack:select from pop_stack where parmf in `popestimate`deaths;
  pop_split:0!.tbl.split[pop_stack;`state`year;`parmf;`valf];
  pop_split:update deathrate:valf_deaths%valf_popestimate from pop_split;
  .graph.xyt[`deathrate xdesc select avg deathrate by state from aas;();0b;`state`deathrate;(`xsort;0b)];
  }

if[not parms[`debug];main[parms];exit 0];
