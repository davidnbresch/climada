function f = gauss_distribution(x, mu, s)
%-

p1 = - (x-mu).^2 /(2*s^2);
p2 = (2*pi*s^2)^(1/2);

f = exp(p1) ./ p2; 

