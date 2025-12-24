
clc; close all; clear;

csvDosyaAdi = 'YoklamaListesi.csv';
guvenEsigi = 0.85;      
onayIcinGerekenKare = 10; 

if ~isfile(csvDosyaAdi)
    basliklar = ["Tarih", "Saat", "Kisi", "Durum"];
    writematrix(basliklar, csvDosyaAdi);

end
disp('Model yükleniyor...');
load('DerinYoklamaModeli.mat');
myNet = yeniNet;
disp('Model hazır!');

% Kamera başlat
cam = webcam;
faceDetector = vision.CascadeObjectDetector;
faceDetector.MergeThreshold = 5; 
inputSize = myNet.Layers(1).InputSize(1:2);

oncekiKisi = "";                
kaydedilenKisiler = strings(0); 
kareSayaci = 0;                 

figure('Name', 'Kararlı Yoklama Sistemi');
hImage = imshow(snapshot(cam));
title('Yoklama Sistemi Başlatıldı...');

% Loop
while ishandle(hImage)
    img = snapshot(cam);
    bboxes = step(faceDetector, img);
    
    if ~isempty(bboxes)
        [~, idx] = max(bboxes(:,3)); 
        bbox = bboxes(idx, :);
        
        % Yüzü Kes
        x=max(1,bbox(1)); y=max(1,bbox(2)); 
        w=min(size(img,2)-x,bbox(3)); h=min(size(img,1)-y,bbox(4));
        
        yuzResmi = imcrop(img, [x, y, w, h]);
        yuzResmi = imresize(yuzResmi, inputSize);
        
        [label, scores] = classify(myNet, yuzResmi);
        maxScore = max(scores);
        suAnkiKisi = string(label);
        
        if maxScore > guvenEsigi
            
            if suAnkiKisi == oncekiKisi
                kareSayaci = kareSayaci + 1; 
            else
                kareSayaci = 0; 
            end

            if ismember(suAnkiKisi, kaydedilenKisiler)
                renk = 'blue';
                kutuMetni = suAnkiKisi + " (VAR)";
                kutuKalinlik = 2;
                
            elseif kareSayaci >= onayIcinGerekenKare
                tarih = string(datetime('now', 'Format', 'dd.MM.yyyy'));
                saat = string(datetime('now', 'Format', 'HH:mm:ss'));
                
                kaydedilenKisiler(end+1) = suAnkiKisi;
                writematrix([tarih, saat, suAnkiKisi, "MEVCUT"], csvDosyaAdi, 'WriteMode', 'append');
                
                fprintf('YOKLAMA ALINDI: %s\n', suAnkiKisi);
                
                renk = 'green';
                kutuMetni = "KAYDEDİLDİ: " + suAnkiKisi;
                kutuKalinlik = 8; 
            
            else
                renk = 'yellow';
                kalan = onayIcinGerekenKare - kareSayaci;
                kutuMetni = "Dogrulaniyor... " + string(kalan);
                kutuKalinlik = 2;
            end
            
            oncekiKisi = suAnkiKisi; 
            
        else
            kareSayaci = 0;
            oncekiKisi = "";
            renk = 'red';
            kutuMetni = "Taninmiyor";
            kutuKalinlik = 1;
        end
        
        img = insertObjectAnnotation(img, 'rectangle', bbox, kutuMetni, ...
            'FontSize', 18, 'LineWidth', kutuKalinlik, 'Color', renk, 'TextColor', 'white');
    else
        kareSayaci = 0;
        oncekiKisi = "";
    end
    
    set(hImage, 'CData', img);
    drawnow;
end
clear cam;
