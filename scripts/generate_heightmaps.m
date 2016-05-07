% Procedural Terrain Generation

n = 512;
m = 100;
i = 0 ;
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
imwrite(z, file);
end

