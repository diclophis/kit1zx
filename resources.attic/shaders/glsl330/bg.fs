#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

uniform float time;

const vec2 iResolution = vec2(512, 512);
float timi = time;
float timx = 0.1;

float sdBox( vec3 p, vec3 b )

{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

 mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

float map(vec3 p)
{
    vec3 q = p;

    vec3 c = vec3(0.2);
    p.z = mod(p.z,c.z)-0.5*c.z;

    vec3 p_s;
    
    p = p * rotationMatrix(vec3(0.0, 0.0, 1.0), sin(floor(q.z) * 10.0) * 4.0 + 0.1 * (timx));
    
    float bars = 1000.0;
    int sides = 8; //int(sin(timi /6.0) * 5.0) + 5;
    float angle = 3.1415 * 2.0 / float(sides);
    
    for ( int i = 0; i < sides; i ++)
    {
        p_s = p * rotationMatrix(vec3(0.0, 0.0, 1.0), angle * float(i));
        
        p_s += vec3(sin(floor(q.z)+ timx* 0.2)* 0.5 + 1.0, sin(q.z), 0.0);
        
        vec3 boxdim = vec3(
            0.06 + sin(q.z * 10.0 + 4.0 + timi) * 0.03 , //0.1 + 0.1 *  sin(timi /6.0) , //* sin(length(p.xy * 20.0))* 0.2, 
            (1.0 + cos(floor(q.z * 0.1) + timx )) * pow(sin((q.z * 2.0) + timx)* 0.5 + 0.5, 3.0) * 20.0 * (0.5 + sin(timx) * 0.5), 
            0.01);

        bars = min(bars, sdBox(p_s, boxdim));  
    }

    float result = bars;   
    return result;
}

// See http://iquilezles.org/www/articles/palettes/palettes.htm for more information
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void getCamPos(inout vec3 ro, inout vec3 rd)
{
    ro.z = timx;
   // ro.x -= sin(timi) 2.0;
}

 vec3 gradient(vec3 p, float t) {
      vec2 e = vec2(0., t);

      return normalize( 
        vec3(
          map(p+e.yxx) - map(p-e.yxx),
          map(p+e.xyx) - map(p-e.xyx),
          map(p+e.xxy) - map(p-e.xxy)
        )
      );
    }


void main( )
{
  timx = timi * 0.1;

  vec2 _p = (-iResolution.xy + 1.0*gl_FragCoord.xy) / iResolution.y;
  _p.y -= 0.5;
  vec3 ray = normalize(vec3(_p, 1.0));
  vec3 cam = vec3(0.0, 0.0, 0.0);
  bool hit = false;
  getCamPos(cam, ray);
  
  float depth = 0.0, d = 0.0, iter = 0.0;
  vec3 p;
  
  for( int i = 0; i < 256; i++)
  {
    p = depth * ray + cam;
      d = map(p);
                
      if (d < 0.0001) {
    hit = true;
          break;
      }
                 
  depth += d * 0.2;
  iter++;
                 
  }
  
  vec3 col = vec3(1.0 - iter / 80.0);

  finalColor = vec4(sqrt(col), hit ? length(p.xy) : 0.0 );
}
