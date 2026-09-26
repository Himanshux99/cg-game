shader_type canvas_item;

// The color you want the silhouette to be
uniform vec4 silhouette_color : source_color = vec4(0.0, 0.7, 1.0, 1.0); 

void fragment() {
    // Read the texture color at the current pixel position
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Set the pixel color to our solid color, but inherit the sprite's original transparency alpha
    COLOR = vec4(silhouette_color.rgb, tex_color.a * silhouette_color.a);
}
