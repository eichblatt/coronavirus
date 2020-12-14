
c:.opts.addopt[`;`debug;1b;"debug"];
c:.opts.addopt[c;`datapath;.file.makepath[`:/home/steve;"projects/coronavirus/data"];"data path"];
c:.opts.addopt[c;`regions;`us`states;"valid regions to query"];
parms:.opts.get_opts c;
show parms;

\l /home/steve/kdb/util/graph.q


load_data:{[parms] data:(parms`regions)!get each .file.makepath[parms`datapath] each parms`regions};
load_census_data:{[parms] 
   pop:("SSSSSSI",15#"F";1#csv)0: .file.makepath[parms[`datapath];`censusPopulation.csv];
   pop:.tbl.rename[pop;cols[pop];lower each cols[pop]];
   pop}
  
main:{[parms]
  data:load_data[parms];
  
  tbl:(select date,state,death from data[`states]),select date,state:`us,death from data[`us];
  tbl:select from tbl where not null death;
  tbl:update dailyDeath:deltas death by state from tbl;
  tbl:update dailyDeath7:mavg[7;dailyDeath] by state from tbl;
  
  pop:load_census_data[parms];
  pop2019:update pop:popestimate2019 from pop;
  tbl:tbl lj select last pop by state from pop2019;
  tbl:update deathrate7:dailyDeath7%pop from tbl;

 
  .graph.xyt[tbl;"state<>`us,state in `NY`CA`TX`WA`IL`NC";`state;`date`dailyDeath7;`]

  }

if[not parms[`debug];main[parms];exit 0];
