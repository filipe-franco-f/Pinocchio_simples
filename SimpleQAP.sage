# -----------------------
# QAP simplificado
# -----------------------
class SimpleQAP: # OK
    """QAP educativo definido pelo usuário.
    Os polinômios v_k(x), w_k(x), y_k(x) são dados como listas de polinômios em F[x].
    t(x) é o polinômio de alvo (vanishing polynomial que anula os pontos das gates).
    """
    def __init__(self, R, v_polys, w_polys, y_polys, t_poly, N):
        # R: PolynomialRing(F, 'x')
        self.R = R
        self.v = v_polys
        self.w = w_polys
        self.y = y_polys
        self.t = t_poly
        self.m = len(v_polys) - 1
        self.N = N  # número de entradas (para I_io)
        self.degree = t_poly.degree()

    def __repr__(self):
        return (f"SimpleQAP(\n"
                f"  R={self.R},\n"
                f"  v={self.v},\n"
                f"  w={self.w},\n"
                f"  y={self.y},\n"
                f"  t={self.t},\n"
                f"  m={self.m},\n"
                f"  N={self.N}\n"
                f")")

    def eval_vector_at(self, s):
        """Avalia todos os polinômios v_k, w_k, y_k em s e retorna listas de valores."""
        v_vals = [poly(s) for poly in self.v]
        w_vals = [poly(s) for poly in self.w]
        y_vals = [poly(s) for poly in self.y]
        t_val = self.t(s)
        return v_vals, w_vals, y_vals, t_val
    
def build_QAP(F: FiniteField):
    # Aqui, vamos montar um QAP para o circuito:
    #
    #    C1    C2  C3
    #      \    \ /
    #       \    x  
    #        \  /C5
    #         x
    #         | C4 (output)
    R.<x> = PolynomialRing(F)
    N = 4
    m = 5
    #
    # Geramos uma raiz aleatória rg em F para cada porta de multiplicação:
    r4 = F.random_element() # porta que tem como saida C4
    r5 = F.random_element() # porta que tem como saida C5

    while r4 == r5:
        r4 = F.random_element()

    def lagrange_poly(v_r4, v_r5):
        return v_r5 * (x - r4)/(r5 - r4) + v_r4 * (x - r5)/(r4 - r5)

    # v_k(rg) = 1 se o fio k é um input esquerdo da porta g
    # Assim, v_1(r4) = 1, v_1(r5) = 0
    # v_2(r4) = 0, v_2(r5) = 1
    # v_k(r) = 0 para qualquer outro k, r. Inclusive k = 0;
    v_polys = [
        lagrange_poly(0, 0),
        lagrange_poly(1, 0),
        lagrange_poly(0, 1),
        lagrange_poly(0, 0),
        lagrange_poly(0, 0),
        lagrange_poly(0, 0),
    ]

    # w_k(rg) = 1 se o fio k é um input direito da porta g
    # Assim, w_5(r4) = 1, w_5(r5) = 0
    # w_3(r5) = 1, w_3(r4) = 0
    # w_k(r) = 0 para qualquer outro k, r. Inclusive k = 0;
    w_polys = [
        lagrange_poly(0, 0),
        lagrange_poly(0, 0),
        lagrange_poly(0, 0),
        lagrange_poly(0, 1),
        lagrange_poly(0, 0),
        lagrange_poly(1, 0),
    ]

    # y_k(rg) = 1 se o fio k é um output da porta g
    # Assim, y_4(r4) = 1, y_4(r5) = 0
    # y_5(r4) = 0, y_5(r5) = 1
    # y_k(r) = 0 para qualquer outro k, r. Inclusive k = 0;
    y_polys = [
        lagrange_poly(0, 0),
        lagrange_poly(0, 0),
        lagrange_poly(0, 0),
        lagrange_poly(0, 0),
        lagrange_poly(1, 0),
        lagrange_poly(0, 1),
    ]

    # t é a multiplicação de (x - rg) para cada porta g
    t_poly = (x - r5)*(x - r4)

    #print(f"Para a raiz r4 = {r4}:")
    #print("v_evaluated:", [v(r4) for v in v_polys])
    #print("w_evaluated:", [w(r4) for w in w_polys])
    #print("y_evaluated:", [y(r4) for y in y_polys])
    #print("=============")
    #print(f"Para a raiz r5 = {r5}:")
    #print("v_evaluated:", [v(r5) for v in v_polys])
    #print("w_evaluated:", [w(r5) for w in w_polys])
    #print("y_evaluated:", [y(r5) for y in y_polys])

    return SimpleQAP(R, v_polys, w_polys, y_polys, t_poly, N=N)

def evaluate_circuit(F: FiniteField, u: list[sage.rings.finite_rings.integer_mod.IntegerMod_int]):
    if len(u) != 3:
        raise IndexError
    # c são os coeficientes dos fios do ciruito
    c = [F(1), u[0], u[1], u[2], u[0]*u[1]*u[2], u[1]*u[2]]
    return c
