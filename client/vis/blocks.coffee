### this module handles the representation of Unicode blocks as geometric regions ###

module = {}

### represent blocks' data within the given layer ###
module.draw = (params) ->
    data = params.data
    module.layer = params.layer
    
    blocks = topojson.feature(data, data.objects.Blocks)
    
    new_block = module.layer.selectAll('.block')
        .data(blocks.features)
      .enter().append('g')
      
    ### the block's area (with tooltip) ###
    new_block.append('path')
        .attr('class', 'block')
        .attr('d', index_module.path_generator)
      .append('title')
        .text((d) -> d.properties.name)
        
    ### the block's symbol ###
    new_block.append('text')
        .attr('class', 'block_symbol')
        .text((d) -> d.properties.symbol)
        .call(place_symbol)
        
    ### blocks borders ###
    module.layer.append('path')
        .datum(topojson.mesh(data, data.objects.Blocks))
        .attr('class', 'block_borders')
        .attr('d', index_module.path_generator)
        
### redraw the blocks' layer-specific stuff according to the current viewport ###
module.redraw = (params) ->
    duration = if params.duration? then params.duration else 0
    easing = if params.easing? then params.easing else 'linear'
    
    ### keep block borders 1-pixel thin ###
    module.layer.selectAll('.block_borders')
      .transition().duration(duration).ease(easing)
        .attr('stroke-width', 1/index_module.zoom.scale())
        
    ### fade block symbols when characters are shown ###
    module.layer.selectAll('.block_symbol')
        .attr('opacity', if index_module.zoom.scale() > index_module.ZOOM.characters then 0.1 else 1)
        
### return the size in pixels of a square that fits within the given datum's path bounds ###
fit_bounds = (d) ->
    bounds = index_module.path_generator.bounds(d)
    return 0.8 * Math.min(bounds[1][0]-bounds[0][0],bounds[1][1]-bounds[0][1])
    
### translate and scale a symbol to fit its block's region ###
place_symbol = () ->
    this
        .attr('transform', (d) -> (
            ### custom placement for some block symbols ###
            pre = ''
            post = ''
            if d.properties.name == 'Hangul Syllables'
                pre = "translate(0 #{-2.2*index_module.zoom.scale()}) "
                post = ' scale(0.6)'
            else if d.properties.name == 'CJK Unified Ideographs Extension C'
                pre = "translate(0 #{-7*index_module.zoom.scale()}) "
                post = ' scale(0.6)'
            else if d.properties.name == 'Private Use Area'
                pre = "translate(0 #{1.8*index_module.zoom.scale()}) "
                
            return "#{pre}translate(#{index_module.path_generator.centroid(d)})#{post}"
        ))
        .attr('font-size', (d) -> "#{fit_bounds(d)}px")
        .attr('dy', (d) -> "#{fit_bounds(d)*0.3}")
        
window.blocks_module = module
