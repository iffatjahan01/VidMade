function ssr
clc; close all;

%% ============================
% USER SETTINGS
%% ============================

photoFolder = 'D:\project\Matlab\ssr';

photos = {'img1.jpg','img2.jpg','img3.jpg','img4.jpg','img5.jpg','img6.jpg','img7.jpg','img8.jpg','img9.jpg','img10.jpg'};

puppyFile = 'puppy.jpg';
musicFile = 'music.mp3';

rawVideo = 'Birthday_NoAudio.mp4';
finalVideo = 'Birthday_Final.mp4';

fps = 30;
photoDisplayTime = 2;
fadeTime = 0.5;

resolution = "4K";


%% ============================
% RESOLUTION
%% ============================

switch resolution
    case "1440p", H = 1440; W = 2560;
    case "4K",    H = 2160; W = 3840;
end


%% ============================
% VIDEO WRITER (NO AUDIO)
%% ============================

v = VideoWriter(rawVideo,"MPEG-4");
v.FrameRate = fps;
open(v);
writeF = @(img) writeVideo(v, im2frame(img));


%% ============================
% MAIN PHOTO LOOP
%% ============================

for i = 1:length(photos)
    img = imread(fullfile(photoFolder, photos{i}));

    frameBase = composePic(img, H, W);  % no distortion

    % Fade-in
    for a = linspace(0,1,round(fadeTime*fps))
        writeF(uint8(double(frameBase)*a));
    end

    % Hold
    for t = 1:(photoDisplayTime * fps)
        writeF(frameBase);
    end

    % Fade-out
    for a = linspace(1,0,round(fadeTime*fps))
        writeF(uint8(double(frameBase)*a));
    end
end


%% ============================
% FINAL PUPPY SLIDE
%% ============================

bg = uint8(255*ones(H,W,3));

puppy = imread(fullfile(photoFolder, puppyFile));
puppy = imresize(puppy, 1.25);   % bigger puppy!

[h,w,~] = size(puppy);
px = round(W*0.08);
py = round(H*0.25);

bg(py:py+h-1, px:px+w-1, :) = puppy;

msg = "Happy Birthday Cutie Pie! ";

bg = insertText(bg, ...
    [round(W*0.55) round(H*0.40)], ...
    msg, ...
    "FontSize", round(H/16), ...
    "BoxOpacity", 0, ...
    "TextColor",[255 20 147]);

baseFrame = bg;


%% ============================
% HEARTS + SPARKLES ANIMATION
%% ============================

numFrames = fps * 3;
numHearts = 25;
numSparkles = 55;

hx = randi([1 W], numHearts, 1);
hy = randi([round(H*0.6) H], numHearts, 1);
hs = randi([3 9], numHearts, 1);

sx = randi([1 W], numSparkles, 1);
sy = randi([1 H], numSparkles, 1);

for t = 1:numFrames
    frame = baseFrame;

    % Hearts float up
    for k = 1:numHearts
        hy(k) = hy(k) - hs(k);
        if hy(k) < 10
            hy(k) = randi([round(H*0.6) H]);
            hx(k) = randi([1 W]);
        end

        frame = insertText(frame, [hx(k) hy(k)], "♥", ...
            "FontSize", 60, ...
            "BoxOpacity",0, ...
            "TextColor", [255 50 100]);
    end

    % Sparkles
    for k = 1:numSparkles
        if rand < 0.2
            frame = insertShape(frame, "FilledCircle", ...
                [sx(k), sy(k), randi([2 6])], ...
                "Color", "yellow", ...
                "Opacity", rand*0.9);
        end
    end

    writeF(frame);
end

close(v);
disp("✓ Video-only file created.");

%% ============================
% ADD AUDIO USING FFMPEG
%% ============================

ff = system("ffmpeg -version");

if ff == 0
    % ffmpeg found
    cmd = sprintf('ffmpeg -y -i "%s" -i "%s" -shortest -c:v copy -c:a aac "%s"', ...
        rawVideo, fullfile(photoFolder,musicFile), finalVideo);
    system(cmd);
    disp("FINAL VIDEO CREATED (with audio)!");
else
    disp("⚠ FFmpeg not installed or not in PATH.");
end

end 

%% ============================
% END OF MAIN SCRIPT
%% ============================


%% ===========================================================
% HELPER FUNCTION — AUTO LETTERBOX WITH BLUR BG (NO DISTORTION)
%% ===========================================================

function frame = composePic(img, H, W)

% Make blurred background
bg = imresize(img, [H W]);
bg = imgaussfilt(bg, 40);

% Keep main image proportional
[h,w,~] = size(img);
ratio = min(H/h, W/w);
newH = round(h*ratio);
newW = round(w*ratio);

img2 = imresize(img, [newH newW]);

% Center it
frame = bg;
y = floor((H - newH)/2);
x = floor((W - newW)/2);

frame(y+1:y+newH, x+1:x+newW, :) = img2;

end
