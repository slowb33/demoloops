{ graphics: lg, mouse: lm, window: lw } = love

import DemoLoop, hsl2rgb from require "demoloop"

class Weekly extends DemoLoop
  metaballs = lg.newShader "
      extern vec2 centers[2];
      extern number hpf;
      extern number lpf;

      varying vec2 vpos;

      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        number val = 0;
        for (int i = 0; i < 2; i++) {
          vec2 quad = pow(vpos + centers[i], vec2(1.8f));
          val += 1.0f / (quad.x + quad.y);
        }

        if (val < hpf) discard;
        if (val > lpf) discard;

        number alpha = min(smoothstep(hpf, hpf*1.07f, val), smoothstep(lpf, lpf/1.4f, val));
        return vec4(color.rgb, alpha);
      }
    ", "
      varying vec2 vpos;
      vec4 position( mat4 transform_projection, vec4 vertex_position )
      {
        vpos = vertex_position.xy;
        return transform_projection * vertex_position;
      }
    "
  vignette = lg.newShader "
      vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = 1 - (screen_coords / love_ScreenSize.xy);
        uv *=  1.0 - uv.xy;
        float vig = uv.x*uv.y * 15.0;
        vig = pow(vig, 0.6);

        return vec4(color.rgb, Texel(texture, texture_coords).a * vig);
      }
    "
  length: 6
  new: =>
    super!

    @font = lg.newFont 'assets/TheNextFont.ttf', lg.getWidth! / 4
    @smallfont = lg.setNewFont 'assets/TheNextFont.ttf', lg.getWidth! / 4 * 0.4
    @time = 0

    @loop = lg.newText @font
    @loop\addf {
        { 255, 255, 255 }, "L",
        { 0, 0, 0, 0 }, "vv",
        { 255, 255, 255 }, "p",
      }, 500, "center", -250, @font\getHeight!/-2
    @year = lg.newText @smallfont
    @year\add "3", @font\getWidth("Loop")/2, @font\getHeight!/-2 - @smallfont\getHeight!/3

    @color = setmetatable {}, { __index: (hue) => with color = { hsl2rgb hue, .3, .3 } do rawset @, hue, color }

    lw.setMode 500, 180
    lg.setBackgroundColor 0, 0, 0, 255

  draw: =>
    sin = (i) -> math.sin(@time / i * math.pi * 2)
    cos = (i) -> math.cos(@time / i * math.pi * 2)

    lg.setShader vignette
    lg.setFont @smallfont
    lg.push!
    lg.translate -200, -200
    lg.rotate 0.2

    weeklywidth = 10 + @smallfont\getWidth "Weekly"
    lg.translate (@time - 7) * weeklywidth, 0

    for y=1, 7
      lg.push!
      for x=1, 12
        lg.setColor @color[(0.1 * y + math.floor(x/3) + @time/6) % 1]
        lg.print "Weekly"
        lg.translate weeklywidth, 0
      lg.pop!
      lg.translate 0, @smallfont\getHeight! + 10
    lg.pop!

    width, height = lg.getDimensions!
    lg.translate width/2 - @year\getWidth! * 0.1, height/2 + 15

    lg.setColor 255, 255, 255
    lg.setShader!
    lg.draw @loop
    lg.draw @year

    lg.setShader metaballs
    mult = 1 + .15 * cos 3
    metaballs\send "hpf", 1/545 * (1 + .15)
    metaballs\send "lpf", 1/100 * mult
    metaballs\send "centers", do
      w = @font\getWidth( "o" ) * (0.75 + .15 * cos 3)
      { -w/2, -6 }, { w/2, -6 }, {}

    lg.rectangle "fill", -106, -54, 200, 140
