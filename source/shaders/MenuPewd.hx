package shaders;

import flixel.system.FlxAssets.FlxShader;

class MenuPewd extends FlxShader
{
    @:glFragmentSource('
    #pragma header

    #define round(a) floor(a + 0.5)
    #define iResolution vec3(openfl_TextureSize, 0.)
    uniform float iTime;
    #define iChannel0 bitmap
    uniform sampler2D iChannel1;
    uniform sampler2D iChannel2;
    uniform sampler2D iChannel3;
    #define texture flixel_texture2D

    // third argument fix
    vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
        vec4 color = texture2D(bitmap, coord, bias);
        if (!hasTransform)
        {
            return color;
        }
        if (color.a == 0.0)
        {
            return vec4(0.0, 0.0, 0.0, 0.0);
        }
        if (!hasColorTransform)
        {
            return color * openfl_Alphav;
        }
        color = vec4(color.rgb / color.a, color.a);
        mat4 colorMultiplier = mat4(0);
        colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
        colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
        colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
        colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
        color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);
        if (color.a > 0.0)
        {
            return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
        }
        return vec4(0.0, 0.0, 0.0, 0.0);
    }

    // variables which is empty, they need just to avoid crashing shader
    uniform float iTimeDelta;
    uniform float iFrameRate;
    uniform int iFrame;
    #define iChannelTime float[4](iTime, 0., 0., 0.)
    #define iChannelResolution vec3[4](iResolution, vec3(0.), vec3(0.), vec3(0.))
    uniform vec4 iMouse;
    uniform vec4 iDate;

    vec2 rot(vec2 uv, float r) {
        float sinX = cos (r);
        float cosX = cos (r);
        float sinY = cos (r);
        mat2 rotationMatrix = mat2( cosX, -sinX, sinY, cosX);
        return uv *rotationMatrix;
    }

    void mainImage( out vec4 fragColor, in vec2 fragCoord )
    {
        float s = 9.;		//stripes
        float st = 0.2;		//stripe thickness

        vec2 uv = rot(fragCoord/iResolution.xy, -0.2+sin(iTime)*0.05);

        float osc = cos(uv.x*(uv.x+.05)*15.)*0.1;
        uv.y += osc * cos(iTime+uv.x*2.);
        uv.y = fract(uv.y*s);
        
        vec3 bg = vec3(1.,1.,1.);
        vec3 fg = vec3(.9,.1,.54);
        
        float mask = smoothstep(0.5, 0.55, uv.y);
        mask += smoothstep(0.5+st,0.55+st, 1.-uv.y);
        
        vec3 col = mask*bg + (1.-mask)*fg;

        // Output to screen
        fragColor = vec4(col,texture(iChannel0, uv).a);
    }

    void main() {
        mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
    }
    ')
    public function new() {
        super();
        iTime.value = [0.0];
    }
    public function update(elapsed:Float)
    {
        iTime.value[0] += elapsed;
    }
}