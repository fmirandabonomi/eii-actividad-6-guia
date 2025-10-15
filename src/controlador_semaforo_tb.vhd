library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use std.textio.all;
use ieee.std_logic_textio.all;
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
        file archivo_estimulo : text open read_mode is "../src/controlador_semaforo_estimulo.txt";
        variable linea_estimulo : line; 
        -- solicitudPeatonA&solicitudPeatonB
        -- &solicitudEmergenciaA&solicitudEmergenciaB
        variable estimulo : std_logic_vector (3 downto 0);
        variable lectura_correcta : boolean;
        variable nr_linea : integer := 0;
        variable duracion_segundos : integer;
    begin
        nreset <= '0';
        wait until rising_edge(clk);
        wait for periodo/4;
        nreset <= '1';
        while not endfile(archivo_estimulo) loop
            nr_linea := nr_linea + 1;
            readline(archivo_estimulo,linea_estimulo);
            read(linea_estimulo,estimulo,lectura_correcta);
            if lectura_correcta then
                read(linea_estimulo,duracion_segundos,lectura_correcta);
            end if;
            if not lectura_correcta then
                report "Línea " & integer'image(nr_linea) & "ignorada"
                severity note;
                next;
            end if;

            solicitudPeatonA = estimulo(3);
            solicitudPeatonB = estimulo(2);
            solicitudEmergenciaA = estimulo(1);
            solicitudEmergenciaB = estimulo(0);
            wait for 1 sec * duracion_segundos;
        end loop;
        wait;
    end process;

    evaluacion : process
        file archivo_patron : text open read_mode is "../src/controlador_semaforo_patron.txt";
        variable linea_patron : line; 
        -- transitoA&peatonA&transitoB&peatonB
        -- &confirmacionPeatonA&confirmacionPeatonB
        -- &confirmacionEmergenciaA&confirmacionEmergenciaB
        variable patron : std_logic_vector (9 downto 0);
        variable lectura_correcta : boolean;
        variable nr_linea : integer := 0;
        variable duracion_segundos : integer;
    begin
        wait until rising_edge(nreset);
        while not endfile(archivo_patron) loop
            nr_linea := nr_linea + 1;
            readline(archivo_patron,linea_patron);
            read(linea_patron,patron,lectura_correcta);
            if lectura_correcta then
                read(linea_patron,duracion_segundos,lectura_correcta);
            end if;
            if not lectura_correcta then
                report "Línea " & integer'image(nr_linea) & "ignorada"
                severity note;
                next;
            end if;
            assert patron(9 downto 8) = transitoA
                report "Semaforo A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(7) = peatonA
                report "Semaforo peatonal A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(6 downto 5) = transitoB
                report "Semaforo B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(4) = peatonB
                report "Semaforo peatonal B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(3) = confirmacionPeatonA
                report "Confirmación de pedido de cruce peatonal A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(2) = confirmacionPeatonB
                report "Confirmación de pedido de cruce peatonal B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(1) = confirmacionEmergenciaA
                report "Confirmación de pedido de emergencia A distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            assert patron(0) = confirmacionEmergenciaB
                report "Confirmación de pedido de emergencia B distinto del esperado en línea "&integer'image(nr_linea)&" del patron"
                severity error;
            wait for 1 sec * duracion_segundos;
        end loop;
        report "Fin de archivo patrón, "&integer'image(nr_linea)&" lineas leidas."
            severity note;
        finish;
    end process;
end tb ; -- tb