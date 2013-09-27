module = {
    ### constants ###
    ZOOM: {
        plane_level: 5,
        characters: 26,
        codepoints: 60
    }
}

on_zoom = () ->
    ### panning actions are not animated ###
    duration = if module.last_zoom_scale == module.zoom.scale() then 0 else 200
    easing = 'linear'
    
    ### transform the layers' root ###
    module.layers
      .transition().duration(duration).ease(easing)
        .attr('transform', "translate(#{module.zoom.translate()}) scale(#{module.zoom.scale()})")
        
    ### redraw all layer-specific stuff ###
    blocks_module.redraw
        duration: duration
        easing: easing
        
    gridchars_module.redraw
        duration: duration
        easing: easing
        
    ### save the current scale to tell if the user pans or zooms ###
    module.last_zoom_scale = module.zoom.scale()
    
window.main = () ->
    ### prepare the vis ###
    module.vis = d3.select('body').append('svg')
        .attr('width', '100%')
        .attr('height', '100%')
        
    ### zoom behavior ###
    module.zoom = d3.behavior.zoom()
        .scaleExtent([0.35, 1024])
        .on('zoom', on_zoom)
        
    module.vis.call(module.zoom)
    
    ### obtain the current viewport to center the chart ###
    bbox = module.vis.node().getBoundingClientRect()
    
    ### set the initial view ###
    module.zoom.translate([bbox.width/2-512*0.35, bbox.height/2-640*0.35])
    module.zoom.scale(0.35)
    
    ### save the current scale to tell if the user pans or zooms ###
    module.last_zoom_scale = module.zoom.scale()
    
    ### custom projection that flips the y axis. see http://bl.ocks.org/mbostock/5663666 for reference ###
    ### for a projection that uses quantitative scales, see http://bl.ocks.org/mbostock/6216797 ###
    module.path_generator = d3.geo.path()
        .projection d3.geo.transform({point: (x,y) -> this.stream.point(x,-y) })
        
    ### get data ###
    d3.json 'vis/data/Blocks.topo.json', (error, data) ->
        ### create the root layer ###
        module.layers = module.vis.append('g').attr('class', 'layers')
        
        ### draw the layers' content ###
        blocks_module.draw
            data: data
            layer: module.layers.append('g').attr('class', 'blocks_layer')
            
        gridchars_module.draw
            layer: module.layers.append('g').attr('class', 'grid_layer')
            
        ### redraw the intial view ###
        on_zoom()
        
window.index_module = module
