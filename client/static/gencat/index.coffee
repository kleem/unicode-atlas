window.main = () ->
    width = 1024
    height = 1280
    
    vis = d3.select('#diagram')
    
    ### custom projection with flipped y axis ###
    path_generator = d3.geo.path()
        .projection d3.geo.transform({point: (x,y) -> this.stream.point(x,-y) })
        
    ### define a color scale for property general_ca ###
    colorify = d3.scale.ordinal()
        .domain(['Lu','Ll','Lt','Lm','Lo','Mn','Mc','Me','Nd','Nl','No','Pc','Pd','Ps','Pe','Pi','Pf','Po','Sm','Sc','Sk','So','Zs','Zl','Zp','Cc','Cf','Cs','Co','Cn'])
        .range(['#2A6289','#708B9E','#80B1D3','#A4CDE9','#B7D4E9','#5F3B8C','#BEBADA','#D6D2ED','#2E897A','#8DD3C7','#AFE9DF','#A33125','#BC766F','#FB7F72','#FD9F95','#881F51','#D15F95','#E8A3C3','#A46620','#FDB462','#FEC789','#FED6A8','#A69B14','#FFE13E','#FFFFB3','#689022','#B3DE69','#CCEF90','#67C45D','#000000'])
        
    ### color the legend ###
    d3.selectAll('#legend rect')
        .style('fill', (d) -> colorify(d3.select(this).attr('class')))
        
    ### load topoJSON data ###
    d3.json '../../data/4_topojson/General cat.topo.json', (error, data) ->
        ### draw the result ###
        vis.selectAll('.region')
            .data(topojson.feature(data, data.objects['General cat']).features)
          .enter().append('path')
            .attr('class', 'region')
            .attr('d', path_generator)
            .attr('fill', (d) -> colorify(d.properties.general_ca))
            