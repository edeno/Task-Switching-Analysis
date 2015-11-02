%% Tints a scaled RGB color (makes it lighter)
function [tintedColor] = tintColor(currentColor)
rgb = (currentColor * 255);
tintedColor = rgb + (255 - rgb) * 0.25;
tintedColor = tintedColor / 255;
end