graph LR
    %% NODO PRINCIPAL
    Root[("🏠 Finanzas Familiares")]

    %% CLASES DE ESTILO
    classDef activos fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef pasivos fill:#ffebee,stroke:#b71c1c,stroke-width:2px;
    classDef ingresos fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px;
    classDef gastos fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef items fill:#fff,stroke:#ccc,stroke-width:1px;
    classDef newitem fill:#fff9c4,stroke:#fbc02d,stroke-width:2px;

    %% --- RAMA 1: LO QUE TENGO (ACTIVOS) ---
    Root --> Tengo(LO QUE TENGO)
    class Tengo activos
    
    Tengo --> Efec(💵 Efectivo)
    Tengo --> Banc(🏦 Bancos)
    Tengo --> Inv(📈 Inversiones)
    
    %% Efectivo
    Efec --> Ef1[Billetera Personal]
    Efec --> Ef2[Caja Menor Casa]
    Efec --> Ef3[Alcancía / Ahorro Físico]

    %% Bancos
    Banc --> C_Aho(Cuenta de Ahorros)
    Banc --> B_Dig(Billeteras Digitales)

    C_Aho --> Ca1[Davivienda]
    C_Aho --> Ca2[Bancolombia]

    B_Dig --> Bd1[DaviPlata]
    B_Dig --> Bd2[Nequi]
    B_Dig --> Bd3[DollarApp]
    B_Dig --> Bd4[PayPal]

    %% Inversiones
    Inv --> In1[CDT / Fiducias]
    Inv --> In2[Propiedades]
    
    class Efec,Banc,Inv,C_Aho,B_Dig activos
    class Ef1,Ef2,Ef3,Ca1,Ca2,Bd1,Bd2,Bd3,Bd4,In1,In2 items

    %% --- RAMA 2: LO QUE DEBO (PASIVOS) ---
    Root --> Debo(LO QUE DEBO)
    class Debo pasivos

    Debo --> TC(💳 Tarjetas de Crédito)
    Debo --> Pres(📉 Préstamos)
    Debo --> CxP(📝 Cuentas por Pagar)

    %% Tarjetas
    TC --> Tc1[Visa / Master]
    TC --> Tc2[Tarjeta Almacenes]

    %% Préstamos (ACTUALIZADO)
    Pres --> Pr1[Hipotecario]
    Pres --> Pr2[Vehículo]
    Pres --> Pr3[Banco Pichincha]
    Pres --> Pr4[Otros]

    %% Cuentas por Pagar
    CxP --> Cp1[Deudas Personales]
    CxP --> Cp2[Servicios Vencidos]
    CxP --> Cp3[Impuestos por Pagar]
    CxP --> Cp4[Otras]

    %% DESGLOSE DE IMPUESTOS POR PAGAR
    Cp3 --> Ip1[Vehicular por Pagar]
    Cp3 --> Ip2[Predial por Pagar]
    Cp3 --> Ip3[Renta por Pagar]
    Cp3 --> Ip4[Otros Impuestos por Pagar]

    class TC,Pres,CxP,Tc1,Tc2,Pr1,Pr2,Pr3,Cp1,Cp2 pasivos
    class Pr4,Cp3,Cp4,Ip1,Ip2,Ip3,Ip4 newitem

    %% --- RAMA 3: DINERO QUE ENTRA (INGRESOS) ---
    Root --> Entra(DINERO QUE ENTRA)
    class Entra ingresos

    Entra --> I_Fijos(Ingresos Fijos)
    Entra --> I_Var(Ingresos Variables / Otros)

    I_Fijos --> I_Sal[Salario / Nómina]
    
    I_Var --> I_Ven[Ventas]
    I_Var --> I_Inv[Rendimientos Inversiones]
    I_Var --> I_Oca[Ganancias Ocasionales]
    I_Var --> I_Otr[Otros Ingresos]

    class I_Fijos,I_Var ingresos
    class I_Sal,I_Ven,I_Inv,I_Oca,I_Otr items

    %% --- RAMA 4: DINERO QUE SALE (GASTOS) ---
    Root --> Sale(DINERO QUE SALE)
    class Sale gastos

    %% 4.1 IMPUESTOS
    Sale --> G_Imp(🏛️ Impuestos)
    G_Imp --> Im1[Vehicular / Rodamiento]
    G_Imp --> Im2[Predial / Vivienda]
    G_Imp --> Im3[Renta / DIAN]
    G_Imp --> Im4[4x1000 / GMF]
    G_Imp --> Im5[Otros Impuestos]

    %% 4.2 SERVICIOS PÚBLICOS / PRIVADOS
    Sale --> G_Ser(Servicios Públicos/Privados)
    G_Ser --> Sp1[EDEQ]
    G_Ser --> Sp2[EPA]
    G_Ser --> Sp3[EfiGas]
    G_Ser --> Sp4[Internet Hogar]
    G_Ser --> Sp5[Internet Móvil]
    G_Ser --> Sp6[Seguros]
    G_Ser --> Sp7[Otros]
    G_Ser --> Sp8[Administración]

    %% 4.3 ALIMENTACIÓN
    Sale --> G_Ali(Alimentación)
    G_Ali --> A_Mer(Mercado)
        A_Mer --> Am01[Frutas]
        A_Mer --> Am02[Verduras]
        A_Mer --> Am03[Hortalizas]
        A_Mer --> Am04[Legumbres]
        A_Mer --> Am05[Granos]
        A_Mer --> Am06[Especias]
        A_Mer --> Am07[Lácteos]
        A_Mer --> Am08[Cárnicos]
        A_Mer --> Am09[Mecato]
        A_Mer --> Am10[Panadería]
        A_Mer --> Am11[Otros Mercado]
    G_Ali --> A_Res[Restaurantes]
    G_Ali --> A_Dom[Domicilios]
    G_Ali --> A_Omn[OmniLife]
    G_Ali --> A_Otr[Otros Alimentación]

    %% 4.4 TRANSPORTE
    Sale --> G_Tra(Transporte)
    G_Tra --> T_Gas[Gasolina]
    G_Tra --> T_Pub[Transporte Público]
    G_Tra --> T_Man[Mantenimiento]
    G_Tra --> T_Seg[Seguros Chana]
    G_Tra --> T_Otr[Otros Transporte]

    %% 4.5 ENTRETENIMIENTO
    Sale --> G_Ent(Entretenimiento)
    G_Ent --> E_Cin[Cine]
    G_Ent --> E_Dep[Deporte]
    G_Ent --> E_Via[Viajes]
    G_Ent --> E_Otr[Otros Entretenimiento]

    %% 4.6 SALUD
    Sale --> G_Sal(Salud)
    G_Sal --> S_Med[Medicamentos]
    G_Sal --> S_Con[Consultas Médicas]
    G_Sal --> S_Seg[Seguros Salud]
    G_Sal --> S_Otr[Otros Salud]

    %% 4.7 EDUCACIÓN
    Sale --> G_Edu(Educación)
    G_Edu --> D_Col[Colegiatura]
    G_Edu --> D_Cur[Cursos]
    G_Edu --> D_Lib[Libros]
    G_Edu --> D_Otr[Otros Educación]

    %% 4.8 ASEO
    Sale --> G_Ase(Aseo)
    G_Ase --> As_Cas[Casa]
    G_Ase --> As_Fam[Familia]
    G_Ase --> As_Otr[Otros Aseo]

    %% 4.9 OTROS GASTOS
    Sale --> G_Otr(Otros Gastos)
    G_Otr --> O_Reg[🎁 Regalos / Mesada]
    G_Otr --> O_Otr[Otros]

    %% Estilos items gastos restantes
    class G_Ali,G_Tra,G_Ent,G_Sal,G_Edu,G_Ase,G_Otr gastos
    class G_Imp,G_Ser items
    class Am01,Am02,Am03,Am04,Am05,Am06,Am07,Am08,Am09,Am10,Am11 items
    class A_Res,A_Dom,A_Omn,A_Otr items
    class T_Gas,T_Pub,T_Man,T_Seg,T_Otr items
    class E_Cin,E_Dep,E_Via,E_Otr items
    class S_Med,S_Con,S_Seg,S_Otr items
    class D_Col,D_Cur,D_Lib,D_Otr items
    class As_Cas,As_Fam,As_Otr items
    class O_Otr,O_Reg items
    class Im1,Im2,Im3,Im4,Im5 items
    class Sp1,Sp2,Sp3,Sp4,Sp5,Sp6,Sp7,Sp8 items
    class Ip1,Ip2,Ip3,Ip4 items