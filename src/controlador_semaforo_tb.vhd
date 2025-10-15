library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.all;

entity controlador_semaforo_tb is
end controlador_semaforo_tb;

architecture tb of controlador_semaforo_tb is

    -- Base de tiempo
    constant Npre : integer := 4;
    constant frecuencia : integer := 10;
    constant Cpre : unsigned(Npre-1 downto 0) := frecuencia - 1;
    constant periodo : time := 1 sec / frecuencia;
    
    -- Configuración semáforo
    constant NTimer : integer := 6;
    constant TVerde  : integer := 50;
    constant TAmarillo : integer := 10;
    constant TPeaton : integer := 50; 

    -- Código de luces
    constant ROJO : std_logic_vector(1 downto 0) := "10";
    constant AMARILLO : std_logic_vector(1 downto 0) := "11";
    constant VERDE : std_logic_vector(1 downto 0) := "01";
    constant NEGRO : std_logic_vector(1 downto 0) := "00";

    -- Solicitudes y confirmaciones emergencia y peaton
    
    signal solicitudPeatonA        : std_logic;
    signal solicitudPeatonB        : std_logic
    signal solicitudEmergenciaA    : std_logic
    signal solicitudEmergenciaB    : std_logic; 
    signal confirmacionPeatonA     : std_logic
    signal confirmacionPeatonB     : std_logic
    signal confirmacionEmergenciaA : std_logic
    signal confirmacionEmergenciaB : std_logic;

    -- Control luces

    signal transitoA : std_logic
    signal transitoB : std_logic_vector(1 downto 0);
    signal peatonA   : std_logic
    signal peatonB   : std_logic;

    -- Reloj y reset

    signal clk    : std_logic
    signal nreset : std_logic;

begin

    dut : entity controlador_semaforo generic map (
        Npre      => Npre,
        Cpre      => Cpre,
        NTimer    => NTimer,
        TVerde    => TVerde,
        TAmarillo => TAmarillo,
        TPeaton   => TPeaton
    ) port map (
        clk => clk,
        nreset => nreset,
        
        solicitudPeatonA        => solicitudPeatonA,
        solicitudPeatonB        => solicitudPeatonB,
        solicitudEmergenciaA    => solicitudEmergenciaA,
        solicitudEmergenciaB    => solicitudEmergenciaB,
        confirmacionPeatonA     => confirmacionPeatonA,
        confirmacionPeatonB     => confirmacionPeatonB,
        confirmacionEmergenciaA => confirmacionEmergenciaA,
        confirmacionEmergenciaB => confirmacionEmergenciaB,

        transitoA => transitoA,
        peatonA   => peatonA,
        transitoB => transitoB,
        peatonB   => peatonB
    );

    reloj : process
    begin
        clk <= '0';
        wait for periodo / 2;
        clk <= '1';
        wait for periodo / 2;
    end process;

    estimulo : process
    begin
        solicitudPeatonA
        solicitudPeatonB
        solicitudEmergenciaA
        solicitudEmergenciaB
        nreset <= '0';
        wait until rising_edge(clk);
        wait for periodo/4;
        nreset <= '1';
        -- Normal (4 ciclos)
        wait for 8 sec * (TVerde + TAmarillo);
        -- Cruce peatonal A, desde verde
        solicitudPeatonA <= '1';
        wait for 1 sec;
        solicitudPeatonA <= '0';
        wait for 1 sec * (TVerde + TPeaton/2 - 1);
        -- Cruce peatonal B, desde rojo
        solicitudPeatonB <= '0';
        wait for 1 sec * (TPeaton/2 + TAmarillo + TVerde - 1);
        -- Emergencia en A, desde cruce peatonal B
        solicitudEmergenciaA <= '1';
        wait for 1 sec * (TPeaton + TAmarillo + TVerde/2);
        solicitudEmergenciaA <= '0';
        -- Emergencia en B, mientras emergencia en A activa;
        solicitudEmergenciaB <= '1';
        wait for 1 sec * (TVerde/2 + TAmarillo + TVerde) + periodo + 35 sec;
        -- Libera emergencia en B luego de 35 segundos extra de verde
        solicitudEmergenciaB <= '0';
        -- Funcionamiento normal
        wait;
    end process;

    evaluacion : process
        constant DURACION_AMARILLO : string := "El amarillo debe durar "& integer'image(TAmarillo) & "s";
        constant A_VERDE_B_ROJO : string := "Cuando A es VERDE B debe ser ROJO";
        constant PEATON_SOLO_PEDIDO : string := "Cruce peatonal solo se habilita con pedido";
        constant PEATON_COINCIDE_VERDE : string := "Cruce peatonal debe coincidir con verde de la misma direccion";
        constant DURACION_VERDE : string := "El verde debe durar " & integer'image(TVerde) & "s";
        constant A_AMARILLO_B_ROJO : string := "Cuando A es AMARILLO B debe ser ROJO";
        constant B_VERDE_A_ROJO : string := "Cuando B es VERDE A debe ser ROJO";
        constant B_AMARILLO_A_ROJO : string := "Cuando B es AMARILLO A debe ser ROJO";
        constant CONFIRMAR_PEDIDO_PEATON : string := "Debe confirmar pedido de cruce peatonal";
        constant PEATON_PEDIDO : string := "Cuando hay un pedido válido de cruce peatonal, debe ser atendido";
        constant FIN_PEDIDO_PEATON : string := "El pedido de cruce se extingue al ser atendido";
        constant CONFIRMAR_PEDIDO_EMERGENCIA : string := "Debe confirmar deteccion de emergencia";
        constant LIBERAR_PEDIDO_EMERGENCIA : string := "Debe liberar pedido de emergencia";
        constant VERDE_DURANTE_EMERGENCIA : string := "Debe permanecer verde durante el paso de emergencia";
        procedure assertVerdeA (inicial : in boolean) is
        begin
            if inicial then
                assert transitoA = VERDE
                    report "Debe iniciar con paso para direccion A"
                    severity error;
            else
                assert transitoA = VERDE
                    report DURACION_AMARILLO
                    severity error;
            end if;
            assert transitoB = ROJO
                report A_VERDE_B_ROJO
                severity error;
            assert not peatonA
                report PEATON_SOLO_PEDIDO
                severity error;
            assert not peatonB
                report PEATON_COINICIDE_VERDE
                severity error;
        end procedure;
        procedure assertVerdeA is
        begin
            assertVerdeA(false);
        end procedure;
        procedure assertAmarilloA is
        begin
            assert transitoA = AMARILLO
                report DURACION_VERDE
                severity error;
            assert transitoB = ROJO
                report A_AMARILLO_B_ROJO
                severity error;
            assert not peatonA
                report PEATON_COINICIDE_VERDE
                severity error;
            assert not peatonB
                report PEATON_COINICIDE_VERDE
                severity error;
        end procedure;
        procedure assertVerdeB is
        begin
            assert transitoB = VERDE
                report DURACION_AMARILLO
                severity error;
            assert transitoA = ROJO
                report B_VERDE_A_ROJO
                severity error;
        end procedure;
        procedure assertAmarilloB is
            assert transitoB = AMARILLO
                report DURACION_VERDE
                severity error;
            assert transitoA = ROJO
                report B_AMARILLO_A_ROJO
                severity error;
        end procedure;
        procedure assertConfirmaPeatonA is
        begin
            assert confirmacionPeatonA
                report CONFIRMAR_PEDIDO_PEATON
                severity error;
        end procedure;
        procedure assertConfirmaPeatonB is
        begin
            assert confirmacionPeatonB
                report CONFIRMAR_PEDIDO_PEATON
                severity error;
        end procedure;
        procedure assertPeatonA is
        begin
            assert transitoA = VERDE
                report PEATON_COINCIDE_VERDE
                severity error;
            assert transitoB = ROJO
                report A_VERDE_B_ROJO
                severity error;
            assert peatonA
                report PEATON_PEDIDO
                severity error;
            assert not confirmacionPeatonA
                report FIN_PEDIDO_PEATON
                severity error;
            assert not peatonB
                report PEATON_COINICIDE_VERDE
                severity error;
        end procedure;
        procedure assertPeatonB is
        begin
            assert transitoB = VERDE
                report PEATON_COINCIDE_VERDE
                severity error;
            assert transitoA = ROJO
                report A_VERDE_B_ROJO
                severity error;
            assert peatonB
                report PEATON_PEDIDO
                severity error;
            assert not confirmacionPeatonB
                report FIN_PEDIDO_PEATON
                severity error;
            assert not peatonA
                report PEATON_COINICIDE_VERDE
                severity error;
        end procedure;
        procedure assertConfirmaEmergenciaA is
        begin
            assert confirmacionEmergenciaA
                report CONFIRMAR_PEDIDO_EMERGENCIA
                severity error;
        end procedure;
        procedure assertLiberaEmergenciaA is
        begin
            assert not confirmacionEmergenciaA
                report LIBERAR_PEDIDO_EMERGENCIA
                severity error;
        end procedure;
        procedure assertConfirmaEmergenciaB is
        begin
            assert confirmacionEmergenciaB
                report CONFIRMAR_PEDIDO_EMERGENCIA
                severity error;
        end procedure;
        procedure assertLiberaEmergenciaB is
        begin
            assert not confirmacionEmergenciaB
                report LIBERAR_PEDIDO_EMERGENCIA
                severity error;
        end procedure;
        procedure assertVerdeEmergenciaA is
        begin
            assert transitoB = VERDE
                report VERDE_DURANTE_EMERGENCIA
                severity error;
            assert transitoA = ROJO
                report B_VERDE_A_ROJO
                severity error;
        end procedure;
    begin
        -- Sincronismo con liberación del reset
        wait until rising_edge(nreset);
        -- cuatro ciclos normal
        for i in 1 to 4 loop
            assertVerdeA(i = 1);
            wait for 1 sec * TVerde;
            assertAmarilloA;
            wait for 1 sec * TAmarillo;
            assertVerdeB;
            wait for 1 sec * TVerde;
            assertAmarilloB;
            wait for 1 sec * TAmarillo
        end loop;
        -- pedido de cruce A en verde A
        wait for 1 sec;
        assertConfirmaPeatonA;
        wait for 1 sec * (TVerde - 1);
        -- cruce peatonal
        assertPeatonA;
        -- pedido cruce en otra dirección
        wait for 1 sec * (TPeaton/2.0) + periodo;
        assertConfirmaPeatonB;
        wait for 1 sec * (TPeaton/2.0) - periodo;
        assertAmarilloA;
        wait for 1 sec * (TAmarillo);
        assertVerdeB;
        wait for 1 sec * (TVerde);
        assertPeatonB;
        wait for periodo;
        assertConfirmaEmergenciaA;
        wait for 1 sec * (TPeaton) - periodo;
        assertAmarilloB;
        wait for 1 sec * (TAmarillo);
        assertVerdeA;
        wait for 1 sec * (TVerde*3 / 4.0);
        assertLiberaEmergenciaA;
        assertConfirmaEmergenciaB;
        assertVerdeEmergenciaA;
        wait for 1 sec * (TVerde / 4.0);
        assertAmarilloA;
        wait for 1 sec * (TAmarillo);
        assertVerdeB;
        wait for 1 sec * (TVerde + 35);
        assertVerdeEmergenciaB;
        wait for 2*periodo;
        assertLiberaEmergenciaB;
        wait for periodo;
        assertAmarilloB;
        wait for 1 sec * TAmarillo;
    end process;
end tb ; -- tb