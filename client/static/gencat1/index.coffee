window.main = () ->
    width = 1024
    height = 1280
    
    vis = d3.select('#diagram')
    
    ### custom projection with flipped y axis ###
    path_generator = d3.geo.path()
        .projection d3.geo.transform({point: (x,y) -> this.stream.point(x,-y) })
        
    ### define a color scale for property general_ca ###
    ### Colorbrewer color scheme: 7-class Set 3 qualitative ###
    colorify = d3.scale.ordinal()
        .domain(['L','M','N','P','S','Z','C'])
        .range(['#80B1D3','#BEBADA','#8DD3C7','#FB8072','#FDB462','#FFFFB3','#B3DE69'])
        
    ### color the legend ###
    d3.selectAll('#legend rect')
        .style('fill', (d) -> colorify(d3.select(this).attr('class')))
        
    ### load topoJSON data ###
    d3.json '../../data/4_topojson/General cat 1.topo.json', (error, data) ->
        ### draw the result ###
        vis.selectAll('.region')
            .data(topojson.feature(data, data.objects['General cat 1']).features)
          .enter().append('path')
            .attr('class', 'region')
            .attr('d', path_generator)
            .attr('fill', (d) -> colorify(d.properties.general_ca))
            