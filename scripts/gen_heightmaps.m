% Terrain Generation
current_path = pwd;
dirpath = '../../data/heightmaps/';

if dirpath(end) ~= '/', dirpath = [dirpath '/']; end
if (exist(dirpath, 'dir') == 0), mkdir(dirpath); end


n = 512; % resolution
m = 100; % n_heigthmaps
i = 0;

disp('Generating heightmaps ...');

while (i < m)
    B = randn(n);
    A = gallery('poisson', n);

    b = reshape(B, (n^2), 1);

    u = A \ b;
    U = reshape(u, n, n);
    y = mat2gray(U);
       z = imgaussfilt(y, 3);
    i = i + 1;
    file = strcat('img', int2str(i), '.png'); 
    out = strcat(dirpath, file);
    imwrite(z, out);
end

disp('Done!');


