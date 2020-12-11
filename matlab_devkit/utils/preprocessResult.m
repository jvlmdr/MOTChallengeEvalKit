function resFileClean = preprocessResult(resFile, seqName, dataDir, force, minvis)
% reads submitted (raw) MOT16 result from .txt
% and removes all boxes that are associated with ambiguous annotations
% such as sitting people, cyclists or mannequins.
% Also removes partially occluded boxes if minvis>0

% resFile='/home/amilan/research/projects/bmtt-dev/code/bae/res/0001/ADL-Rundle-6.txt';
% seqName = 'MOT16-09';
assert(cleanRequired(seqName),'preproccessing should only be done for MOT16/17 and MOT20')

if nargin<4, force=1; end
if nargin<5, minvis=0; end

fprintf('Preprocessing (cleaning) %s...\n',seqName);


% if file does not exist, do nothing
if ~exist(resFile,'file')
    fprintf('Results file does not exist\n');
    resFileClean = []; 
    return;
end

[p,f,e]=fileparts(resFile);
cleanDir = [p,filesep,'clean'];
if ~exist(cleanDir, 'dir'), mkdir(cleanDir); end
resFileClean = [cleanDir,filesep,f,e];

% if clean file already exists and no need to redo, skip
if ~force && exist(resFileClean, 'file')
    fprintf('skipping...\n');
    return;
end

% if file empty, just copy it
tf = dir(resFile);
if tf.bytes == 0
    fprintf('Results file empty\n');
    copyfile(resFile,resFileClean);
    return;
end

if nargin<3, dataDir = getDataDir; end

% [seqName, seqFolder, imgFolder, imgExt, F, dirImages] ...
%     = getSeqInfo(seq, dataDir);

[seqName, seqFolder, imgFolder, frameRate, F, imWidth, imHeight, imgExt] ...
    = getSeqInfoFromFile(seqName, dataDir);

% read in result
resRaw = dlmread(resFile);



%%

% read ground truth
gtFolder = [dataDir,filesep,'gt',filesep];
gtFile = [gtFolder,'gt.txt'];
gtRaw = dlmread(gtFile);

% make sure we have MOT16 ground truth (= 9 columns)
assert(size(gtRaw,2)==9, 'unknown GT format')

% define which classes should be ignored
if ~isempty(strfind(seqName,'MOT20'))
    distractors = {'person_on_vhcl','static_person','distractor','reflection', 'non_mot_vhcl'};

else 
    distractors = {'person_on_vhcl','static_person','distractor','reflection'};
end

keepBoxes = true(size(resRaw,1),1);

showVis = 0;

td=0.5; % overlap threshold
for t=1:F
    if ~mod(t,100), fprintf('.'); end
    
    % find all result boxes in this frame
    resInFrame = find(resRaw(:,1)==t); N = length(resInFrame);
    resInFrame = reshape(resInFrame,1,N);
    
    % find all GT boxes in frame
    GTInFrame = find(gtRaw(:,1)==t); Ngt = length(GTInFrame);
    GTInFrame = reshape(GTInFrame,1,Ngt);

    bxgt=gtRaw(GTInFrame,3); bygt=gtRaw(GTInFrame,4); bwgt=gtRaw(GTInFrame,5); bhgt=gtRaw(GTInFrame,6);
    bxres=resRaw(resInFrame,3); byres=resRaw(resInFrame,4); bwres=resRaw(resInFrame,5); bhres=resRaw(resInFrame,6);
    % Compute IOU using broadcasting.
    vol_gt = max(0, bwgt) .* max(0, bhgt);
    vol_res = max(0, bwres) .* max(0, bhres);
    xmin_isect = max(bxgt, bxres');
    xmax_isect = min(bxgt + bwgt, (bxres + bwres)');
    ymin_isect = max(bygt, byres');
    ymax_isect = min(bygt + bhgt, (byres + bhres)');
    vol_isect = max(0, xmax_isect - xmin_isect) .* max(0, ymax_isect - ymin_isect);
    vol_isect = min(vol_isect, min(vol_gt, vol_res'));  % Ensure intersection is smaller.
    vol_union = vol_gt + vol_res' - vol_isect;
    allisects = vol_isect ./ vol_union;
    allisects(vol_union == 0) = 0;

    is_candidate = (allisects >= 1 - td);
    eps = 1 / (max(size(allisects)) + 1);
    cost_matrix = -(is_candidate + eps * (allisects .* is_candidate));
    Mtch_neg = MinCostMatching(cost_matrix);
    Mtch_neg = Mtch_neg .* is_candidate;  % Mask zero-value matches.
    isect_neg = sum(allisects(find(Mtch_neg)));

    tmpai=allisects;
    tmpai=1-tmpai;
    tmpai(tmpai>td)=Inf;
    Mtch_pos = MinCostMatching(tmpai);
    Mtch_pos = Mtch_pos .* is_candidate;
    isect_pos = sum(allisects(find(Mtch_pos)));

    assert(sum(sum(Mtch_neg)) == sum(sum(Mtch_pos)));
    assert((isect_neg - isect_pos) / max(Ngt, 1) <= 1e-8);

    [mGT,mRes]=find(Mtch_neg);
%     pause
    nMtch = length(mGT);
    % go through all matches
    for m=1:nMtch        
        g=GTInFrame(mGT(m)); % gt box 
        gtClassID = gtRaw(g,8);
        gtClassString = classIDToString(gtClassID);
        
        % if we encounter a distractor, mark to remove box
        if ismember(gtClassString, distractors)
            r = resInFrame(mRes(m)); % result box
            keepBoxes(r) = false;
            
            if showVis
                bxgt=gtRaw(g,3); bygt=gtRaw(g,4); bwgt=gtRaw(g,5); bhgt=gtRaw(g,6); idgt=gtRaw(g,2);
                bxres=resRaw(r,3); byres=resRaw(r,4); bwres=resRaw(r,5); bhres=resRaw(r,6); idres=resRaw(r,2);

                clf
                im = imread(fullfile(dataDir,seqName,'img1',sprintf('%06d.jpg',t)));
                imshow(im); hold on
                text(50,50,sprintf('%d',t),'color','w')
                
                % show GT box
%                 text(bxgt,bygt-20,sprintf('%d',idgt),'color','w')
                classString = insertEscapeChars(classIDToString(gtClassID));
                text(bxgt+50,bygt-20,sprintf('%s',classString),'color','w')     
                rectangle('Position',[bxgt,bygt,bwgt,bhgt],'EdgeColor','w');
                
                % show Res box
%                 text(bxres,byres-20,sprintf('%d',idres),'color','y')
                rectangle('Position',[bxres,byres,bwres,bhres],'EdgeColor','y');
                
                pause(.01)
            end
        end
        
        % if we encounter a partially occluded box, mark to remove
        if gtRaw(g,9)<minvis
            r = resInFrame(mRes(m)); % result box
            keepBoxes(r) = false;
            
            if showVis
                bxgt=gtRaw(g,3); bygt=gtRaw(g,4); bwgt=gtRaw(g,5); bhgt=gtRaw(g,6); idgt=gtRaw(g,2);
                bxres=resRaw(r,3); byres=resRaw(r,4); bwres=resRaw(r,5); bhres=resRaw(r,6); idres=resRaw(r,2);

                clf
                im = imread(fullfile(dataDir,seqName,'img1',sprintf('%06d.jpg',t)));
                imshow(im); hold on
                text(50,50,sprintf('%d',t),'color','w')
                
                % show GT box
                text(bxgt+50,bygt-20,sprintf('vis %.1f',gtRaw(g,9)*100),'color','w')     
                rectangle('Position',[bxgt,bygt,bwgt,bhgt],'EdgeColor','w');
                
                % show Res box
%                 text(bxres,byres-20,sprintf('%d',idres),'color','y')
                rectangle('Position',[bxres,byres,bwres,bhres],'EdgeColor','y');
                
                pause(.01)
                pause
            end
        end        
        
    end
end

%%
fprintf('\nRemoving %d boxes from %s solution...\n',[numel(find(~keepBoxes)), seqName]);
resNew = resRaw;
resNew=resNew(keepBoxes,:);

%% write new file into new dir (clean)
dlmwrite(resFileClean, resNew);




% end
