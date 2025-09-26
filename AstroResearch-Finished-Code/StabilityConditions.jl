G = 2945.49 #gravitational constant
C = 37242 #Speed o' light

function differential(m1, m2, a, e)
	 h = (-128/5)*(G^3)*(C^(-5))*(m1+m2)/(2*pi*(a^3))
	 d = m1*m2*((1-(e^2))^(-7/2))*(1 + (73/24)*(e^2) + (37/96)*(e^4))
	 x = h*d
	 return a/x

end

function lagrangian(m1, m2, m3, a2)

	 M = m1 + m2
	 L1 = a2*(0.5 - 0.227*log(10, (m3/M)))
	 L2 = a2*(0.5 + 0.227*log(10, (m3/M)))
	 return L1, L2

end
