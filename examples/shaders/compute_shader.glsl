#version 460 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba32f, binding = 0) uniform image2D screen;

uniform float zoom;
uniform vec2 offset;

float distanceToMandelbrot(in vec2 c)
{
    // Pre-computation checks for optimization
    {
        float c2 = dot(c, c);
        // skip computation inside M1
        if (256.0 * c2 * c2 - 96.0 * c2 + 32.0 * c.x - 3.0 < 0.0) return 0.0;
        // skip computation inside M2
        if (16.0 * (c2 + 2.0 * c.x + 1.0) - 1.0 < 0.0) return 0.0;
    }

    // Iteration
    float di = 1.0;
    vec2 z = vec2(0.0);
    float m2 = 0.0;
    vec2 dz = vec2(0.0);
    for (int i = 0; i < 300; i++)
    {
        if (m2 > 1024.0) { di = 0.0; break; }

        // Z' -> 2·Z·Z' + 1
        dz = 2.0 * vec2(z.x * dz.x - z.y * dz.y, z.x * dz.y + z.y * dz.x) + vec2(1.0, 0.0);

        // Z -> Z² + c         
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;

        m2 = dot(z, z);
    }

    // Distance calculation
    float d = 0.5 * sqrt(dot(z, z) / dot(dz, dz)) * log(dot(z, z));
    if (di > 0.5) d = 0.0;

    return d;
}

void main()
{
    ivec2 texel_coords = ivec2(gl_GlobalInvocationID.xy);
    vec2 screen_resolution = vec2(imageSize(screen));
    vec2 normalized_coords = (vec2(texel_coords) + vec2(0.5)) / screen_resolution * 2.0 - 1.0;
    float aspect_ratio = screen_resolution.x / screen_resolution.y;

    vec2 p = normalized_coords * vec2(aspect_ratio, 1.0);

    // Use the uniform float zoom for zooming and uniform vec2 offset for moving
    vec2 c = vec2(-0.05, 0.6805) + offset + p * zoom;

    // Distance to Mandelbrot
    float d = distanceToMandelbrot(c);

    // Soft coloring based on distance
    d = clamp(pow(4.0 * d / zoom, 0.2), 0.0, 1.0);

    vec3 col = vec3(d);

    imageStore(screen, texel_coords, vec4(col, 1.0));
}
