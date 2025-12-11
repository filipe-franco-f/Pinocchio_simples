# Implementa uma versão didática e simplificada do protocolo Pinocchio
# Observação: esta implementação SIMULA grupos bilineares de forma algebraica
# (representando elementos de G por expoentes inteiros) para facilidade de
# entendimento e execução sem dependências criptográficas reais.

load("SimpleQAP.sage")

# -----------------------
# Utilitários e simulações
# -----------------------
class BilinearGroupSimulator:
    """Simula um grupo cíclico G de ordem q e um emparelhamento e: G x G -> G_T.
    Representamos elementos de G por inteiros (o expoente sobre um gerador g).
    O emparelhamento é simulado como e(g^a, g^b) = GT^{a*b} (representado por (a*b)).

    Isto é suficiente para testar a lógica algebraica do Pinocchio sem
    usar curvas elípticas / bibliotecas de emparelhamento.
    """
    def __init__(self, q=None):
        # escolha uma ordem de grupo grande (primo)
        if q is None:
            q = next_prime(2**127)
        self.q = int(q)
        self.g = 1  # representação do gerador: expoente 1

    def g_pow(self, exponent):
        """Retorna a representação de g^{exponent} em G (expoente mod q)."""
        return exponent

    def element_mul(self, a, b):
        # multiplicação em G corresponde a soma de expoentes
        return (a + b)
    
    def tri_element_mul(self, a, b, c):
        # multiplicação em G corresponde a soma de expoentes
        return (a + b + c)

    def pairing(self, a, b):
        """Simula o emparelhamento: e(g^a, g^b) = GT^{a*b}.
        Representamos elementos de GT por um número (expoente sobre gerador de GT).
        """
        return (a * b)

    def equal_GT(self, x, y):
        return (x - y) == 0

# -----------------------
# Funções do protocolo
# -----------------------

def keygen(sim: BilinearGroupSimulator, Q: SimpleQAP, field):
    """Gera EK e VK simulados conforme a descrição.
    Retorna (EK, VK, secrets)
    """
    q = sim.q
    # segredos aleatórios
    r_v = field.random_element()
    r_w = field.random_element()
    s = field.random_element()
    alpha_v = field.random_element()
    alpha_w = field.random_element()
    alpha_y = field.random_element()
    beta = field.random_element()
    gamma = field.random_element()
    r_y = r_v * r_w

    # avaliar polinômios em s
    v_vals, w_vals, y_vals, t_val = Q.eval_vector_at(s)

    v_vals_io, v_vals_mid = v_vals[:Q.N+1], v_vals[Q.N+1:]
    w_vals_io, w_vals_mid = w_vals[:Q.N+1], w_vals[Q.N+1:]
    y_vals_io, y_vals_mid = y_vals[:Q.N+1], y_vals[Q.N+1:]


    EK = {
        'g_v_vals': [sim.g_pow(r_v * v) for v in v_vals_mid],
        'g_w_vals': [sim.g_pow(r_w * w) for w in w_vals_mid],
        'g_y_vals': [sim.g_pow(r_y * y) for y in y_vals_mid],
        'g_alpha_v_vals': [sim.g_pow((r_v * alpha_v * v)) for v in v_vals_mid],
        'g_alpha_w_vals': [sim.g_pow((r_w * alpha_w * w)) for w in w_vals_mid],
        'g_alpha_y_vals': [sim.g_pow((r_y * alpha_y * y)) for y in y_vals_mid],
        's_pows': [sim.g_pow(s**i) for i in range(1, Q.degree + 1)],
        'g_combinations': [sim.tri_element_mul(r_v * beta * v_vals_mid[k], r_w * beta * w_vals_mid[k], r_y * beta * y_vals_mid[k]) for k in range(len(v_vals_mid))]
    }
    print("EK:\n", EK)

    VK = {
        'g': sim.g,
        'g_alpha_v': sim.g_pow(alpha_v),
        'g_alpha_w': sim.g_pow(alpha_w),
        'g_alpha_y': sim.g_pow(alpha_y),
        'g_gamma': sim.g_pow(gamma),
        'g_beta_gamma': sim.g_pow(beta * gamma),
        'g_t_s_y': sim.g_pow(r_y * t_val),
        # guardar as primeiras N+1 (k in {0} U [N]) avaliações
        'g_v_io': [sim.g_pow(r_v * v_val_io) for v_val_io in v_vals_io],
        'g_w_io': [sim.g_pow(r_w * w_val_io) for w_val_io in w_vals_io],
        'g_y_io': [sim.g_pow(r_y * y_val_io) for y_val_io in y_vals_io],
    }

    print("VK:\n", VK)

    secrets = {
        'r_v': r_v, 'r_w': r_w, 'r_y': r_y, 's': s,
        'alpha_v': alpha_v, 'alpha_w': alpha_w, 'alpha_y': alpha_y,
        'beta': beta, 'gamma': gamma
    }

    print("secrets:\n", secrets)

    return EK, VK, secrets


def prover_make_proof(sim: BilinearGroupSimulator, Q: SimpleQAP, EK, secrets, F, u):
    """Dado QAP Q, EK, o corpo F do QAP e a testemunha u do circuito,
    constrói v_mid, w_mid, y_mid, h e retorna a prova (conjunto de expoentes simulados).
    """
    # c: lista de tamanho m+1 com coeficientes c_k em F.
    c = evaluate_circuit(F, u)
    print("Circuit coeficients: \n", c)
    s = secrets['s']
    r_v = secrets['r_v']; r_w = secrets['r_w']; r_y = secrets['r_y']

    I_mid = list(range(Q.N + 1, Q.m+1))

    # aqui montamos p como (V * W - Y) usando polinômios completos
    v_total = Q.R(0); w_total = Q.R(0); y_total = Q.R(0)
    for k in range(Q.m+1):
        v_total += c[k] * Q.v[k]
        w_total += c[k] * Q.w[k]
        y_total += c[k] * Q.y[k]

    p = expand(v_total * w_total - y_total)

    # dividir p por t(x)
    h, rem = p.quo_rem(Q.t)
    if rem != 0:
        print("\n\n============================================================================")
        print('p(x) não é divisível por t(x) — prova inválida. Construindo uma prova FALSA')


    v_mid_poly = Q.R(0)
    w_mid_poly = Q.R(0)
    y_mid_poly = Q.R(0)
    for k in I_mid:
        v_mid_poly += c[k] * Q.v[k]
        w_mid_poly += c[k] * Q.w[k]
        y_mid_poly += c[k] * Q.y[k]

    # avaliações em s
    v_mid_s = v_mid_poly(s)
    w_mid_s = w_mid_poly(s)
    y_mid_s = y_mid_poly(s)

    proof = {
        'g_v_mid': sim.g_pow(r_v * v_mid_s),
        'g_w_mid': sim.g_pow(r_w * w_mid_s),
        'g_y_mid': sim.g_pow(r_y * y_mid_s),
        'g_h': sim.g_pow(h(s)),
        'g_alpha_v_vmid': sim.g_pow(r_v * secrets['alpha_v'] * v_mid_s),
        'g_alpha_w_wmid': sim.g_pow(r_w * secrets['alpha_w'] * w_mid_s),
        'g_alpha_y_ymid': sim.g_pow(r_y * secrets['alpha_y'] * y_mid_s),
        'g_beta_vwy': sim.g_pow(secrets['beta'] * (r_v * v_mid_s + r_w * w_mid_s + r_y * y_mid_s))
    }
    print("proof: \n", proof)

    return proof


def verifier_check(sim: BilinearGroupSimulator, Q: SimpleQAP, VK, proof, public_coeffs: list[int], secrets=None): # OK
    """Executa as três checagens de verificação conforme a descrição.
    public_coeffs: coeficientes públicos para entradas/saídas (lista c_k para k in [0..N])
    """
    # 1) Checagem da divisibilidade (usando produto das avaliações públicas)
    # reconstrói g^{v_io(s)}_v a partir de VK['g_v_io'] e public_coeffs

    g_v_io_comb = 0
    g_w_io_comb = 0
    g_y_io_comb = 0
    for k in range(1, Q.N + 1):
        c = public_coeffs[k]
        g_v_io_comb = sim.element_mul(g_v_io_comb, sim.g_pow(c * (VK_get_eval(VK,'v',k))))
        g_w_io_comb = sim.element_mul(g_w_io_comb, sim.g_pow(c * (VK_get_eval(VK,'w',k))))
        g_y_io_comb = sim.element_mul(g_y_io_comb, sim.g_pow(c * (VK_get_eval(VK,'y',k))))


    # juntar com valores mid vindos da prova e o índice 0 (constantes)
    lhs1 = sim.element_mul(VK['g_v_io'][0], sim.element_mul(g_v_io_comb, proof['g_v_mid']))
    lhs2 = sim.element_mul(VK['g_w_io'][0], sim.element_mul(g_w_io_comb, proof['g_w_mid']))


    # e(g^{v_total}, g^{w_total})
    e_left = sim.pairing(lhs1, lhs2) # (1)

    e_right_1 = sim.pairing(VK['g_t_s_y'], proof['g_h'])
    rhs_y = sim.element_mul(VK['g_y_io'][0], sim.element_mul(g_y_io_comb, proof['g_y_mid']))
    e_right_2 = sim.pairing(rhs_y, sim.g)

    e_right =  sim.element_mul(e_right_1, e_right_2)

    check1 = sim.equal_GT(e_left, e_right) # (1) == (2)

    # 2) Checagem dos subespaços: e(g^{alpha_v}, g^{v_mid}) == e(g, g^{alpha_v v_mid})
    c2_1 = sim.pairing(VK['g_alpha_v'], proof['g_v_mid'])
    c2_2 = sim.pairing(sim.g, proof['g_alpha_v_vmid'])
    c2 = sim.equal_GT(c2_1, c2_2)

    c2_3 = sim.pairing(VK['g_alpha_w'], proof['g_w_mid'])
    c2_4 = sim.pairing(sim.g, proof['g_alpha_w_wmid'])
    c2w = sim.equal_GT(c2_3, c2_4)

    c2_5 = sim.pairing(VK['g_alpha_y'], proof['g_y_mid'])
    c2_6 = sim.pairing(sim.g, proof['g_alpha_y_ymid'])
    c2y = sim.equal_GT(c2_5, c2_6)

    # 3) Consistência dos coeficientes
    left3 = sim.pairing(sim.element_mul(proof['g_v_mid'], sim.element_mul(proof['g_w_mid'], proof['g_y_mid'])), VK['g_beta_gamma'])
    right3 = sim.pairing(proof['g_beta_vwy'], VK['g_gamma'])
    c3 = sim.equal_GT(left3, right3)

    return {'divisibility': check1, 'subspaces': (c2 and c2w and c2y), 'consistency': c3}

# helpers para extrair avaliações do VK guardadas

def VK_get_eval(VK, which, k):
    if which == 'v':
        return VK['g_v_io'][k]
    if which == 'w':
        return VK['g_w_io'][k]
    if which == 'y':
        return VK['g_y_io'][k]
    raise KeyError

if __name__ == '__main__':
    # campo F
    p = next_prime(2**61)
    F = GF(p)
    Q = build_QAP(F)
    print(Q)

    # init simulador de grupos
    sim = BilinearGroupSimulator()

    EK, VK, secrets = keygen(sim, Q, F)

    # Testemunha de entrada do circuito:
    u_in = [F(3), F(5), F(7)]

    # Saída alegada:
    # Pelo circuito, u_out = u_in[0] * u_in[1] * u_in[2]
    u_out = F(105)  # 3 * 5 * 7 = 105

    u = u_in + [u_out]

    # Será produzida uma prova para o resultado do circuito aplicado a entrada u
    c = evaluate_circuit(F, u)
    proof = prover_make_proof(sim, Q, EK, secrets, F, u)
    public_coeffs = c[:Q.N+1]  # c_0..c_N

    result = verifier_check(sim, Q, VK, proof, public_coeffs)

    print('\n\nResultado das checagens:', result)
    # espera-se True se tudo for consistente na simulação
