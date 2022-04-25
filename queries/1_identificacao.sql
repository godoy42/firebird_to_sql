SET TERM ^ ;
EXECUTE BLOCK
RETURNS (
    STR_SITUACAO varchar(20),
    FORMATO varchar(50),
    CODIGO_ANIMAL integer,
    NOME_USUAL_SERIE varchar(15),
    NOME_USUAL_NUMERO integer,
    DIAS_SITUACAO integer,
    DIAS_ABATE integer,
    DIAS_CERTIFICACAO integer,
    PAI_SERIE varchar(15),
    PAI_NUMERO integer,
    MAE_SERIE varchar(15),
    MAE_NUMERO integer,
    AVO_PATERNO_SERIE varchar(15),
    AVO_PATERNO_NUMERO integer,
    AVO_PATERNA_SERIE varchar(15),
    AVO_PATERNA_NUMERO integer,
    AVO_MATERNO_SERIE varchar(15),
    AVO_MATERNO_NUMERO integer,
    AVO_MATERNA_SERIE varchar(15),
    AVO_MATERNA_NUMERO integer,
    MAE_RECEP_SERIE varchar(15),
    MAE_RECEP_NUMERO integer,
    NOME_USUAL varchar(15),
    SEXO varchar(1),
    RACA varchar(80),
    TIPO_GRAU varchar(10),
    DATA_NASCIMENTO date,
    TIPO varchar(20),
    LOCALIDADE varchar(80),
    INVENTARIO date,
    AVO_MATERNO varchar(15),
    CATEGORIA_ERP varchar(30),
    PAI varchar(15),
    MAE varchar(15) )

AS
declare variable cod_animal integer;
  declare variable sex_animal integer;
  declare variable tip_animal integer;
  declare variable v_sit integer;
  declare variable v_formato varchar(50);
  declare variable v_DATA_NASC DATE;
  declare variable Data_Inv DATE;
  declare variable Data_Saida DATE;
  declare variable vCategoria_Femea varchar(20);
   Declare variable v_nome_usual varchar(015);
   Declare variable v_sexo varchar(001);
   Declare variable v_raca varchar(080);
   Declare variable v_tipo_grau varchar(010);
   Declare variable v_data_nascimento date;
   Declare variable v_tipo varchar(020);
   Declare variable v_localidade varchar(080);
   Declare variable v_inventario date;
   Declare variable v_nome_avo_materno varchar(015);
   Declare variable vCatERP varchar(030);
   Declare variable v_nome_pai varchar(015);
   Declare variable v_nome_mae varchar(015);
BEGIN
data_inv = null;
For
   Select
      a.codigo_animal,
      a.sexo,
      a.tipo,
      a.situacao,
      a.data_nascimento,
      a.nome_usual_serie,
      a.nome_usual_numero,
      case 
         when (rf.TEMPO_ASERVIR is not null) then rf.TEMPO_ASERVIR 
         when (rf.TEMPO_SERV_GEST is not null) then rf.TEMPO_SERV_GEST 
         when (rf.TEMPO_POS_PARTO is not null) then rf.TEMPO_POS_PARTO 
         else 0
      end as tempo_sit, 
      case
         when (las.data_liberacao is not null and las.data_liberacao > 'now') then (las.data_liberacao - Cast('now' as date))
         else 0
      end as dias_abate,
      case
         when (a.dt_certif_sisbov is not null) then Cast('now' as date) - a.dt_certif_sisbov
         else 0
      end as dias_certificacao,
      case
         when (a.situacao = 4) then (select first 1 v.data from vendas v where v.codigo_animal = a.codigo_animal and v.data_devolucao is null order by v.data desc)
         when (a.situacao = 5) then (select first 1 m.data from mortes m where m.codigo_animal = a.codigo_animal order by m.data desc)
         when (a.situacao > 5) then (select first 1 s.data_saida from saidas_animais s where s.codigo_animal = a.codigo_animal and s.data_devolucao is null order by s.data_saida desc)
         else Cast('now' as date)
      end as data_saida
      , case when a.sexo = 0 then rcf.categoria_femea else rcf.categoria_estoque end 
, a.nome_usual
, r.descricao as raca
, a.tipo_grau
, a.data_nascimento
, loc.nome
, ( select first 1 inv.data from inventario_animais inv where (inv.codigo_animal = a.codigo_animal) order by inv.data desc) as inventario
, amvp.nome_usual as avo_materno, amvp.nome_usual_serie, amvp.nome_usual_numero
, (
     select
        case rcee.categoria
           when 1 then 'Touro'
           when 2 then 'Vaca'
           when 3 then 'Vaca (Circulante)'
           when 4 then 'Novilha Reprodução'
           when 5 then 'Novilha'
           when 6 then 'Bezerra'
           when 7 then 'Boi'
           when 8 then 'Tourinho'
           when 9 then 'Garrote'
           when 10 then 'Garrote'
           when 11 then 'Bezerro'
        end as categoria_estoque
     from
        retorna_categoria_estoque_erp(a.codigo_fazenda,  a.codigo_animal, current_date) rcee
  )
, ap.nome_usual as pai, ap.nome_usual_serie, ap.nome_usual_numero
, am.nome_usual as mae, am.nome_usual_serie, am.nome_usual_numero
from animais a
LEFT JOIN RET_RESUMO_FEMEA(A.CODIGO_ANIMAL) RF ON
          A.CODIGO_ANIMAL = RF.FEMEA_VAZIA_ASERVIR OR
          A.CODIGO_ANIMAL = RF.FEMEA_SERV_GEST OR
          A.CODIGO_ANIMAL = RF.FEMEA_POS_PARTO
left join
   retorna_categoria_femea(a.codigo_animal, current_date) rcf on (rcf.codigo_animal = a.codigo_animal)
left join ret_idade_anosmeses(a.data_nascimento, 
      case
         when (a.situacao = 4) then (select first 1 v.data from vendas v where v.codigo_animal = a.codigo_animal and v.data_devolucao is null order by v.data desc)
         when (a.situacao = 5) then (select first 1 m.data from mortes m where m.codigo_animal = a.codigo_animal order by m.data desc)
         when (a.situacao > 5) then (select first 1 s.data_saida from saidas_animais s where s.codigo_animal = a.codigo_animal and s.data_devolucao is null order by s.data_saida desc)
         else Cast('now' as date)
      end
                             ) ri on (ri.meses is not null)
left join fazendas f on (f.codigo_fazenda = a.codigo_fazenda)
left join liberado_abate_sisbov(a.codigo_animal, :data_inv) las on (las.codigo_animal = a.codigo_animal)
left join
   tratamentos_animais ta on (ta.codigo_tratamento_animal = (select
                                                                first 1
                                                                ta1.codigo_tratamento_animal
                                                             from
                                                                tratamentos_animais ta1
                                                             left join
                                                                tratamentos t1 on (t1.codigo_tratamento = ta1.codigo_tratamento)
                                                             where
                                                                (ta1.codigo_animal = a.codigo_animal)
                                                                and ( (ta1.data + t1.dias_carencia_abate) > 'now')
                                                             order by ta1.data desc 
                                                            )
                             )
left join
   tratamentos t on (ta.codigo_tratamento = t.codigo_tratamento)
left join
   transferencias_fazendas tf on (tf.codigo_transf_fazenda = (select
                                                                 first 1
                                                                 tf1.codigo_transf_fazenda
                                                              from
                                                                 transferencias_fazendas tf1
                                                              where
                                                                 (tf1.codigo_animal = a.codigo_animal)
                                                                 and (tf1.fazenda_destino = a.codigo_fazenda)
                                                                 and ((tf1.data + 40) > 'now')
                                                               order by tf1.data desc 
                                                             )
                                 )
left join SP_CALCULA_NABC(287,A.CODIGO_ANIMAL,0) NABC on (nabc.ret_codigo_animal = a.codigo_animal)
left join RET_COMP_RACIAL(A.CODIGO_ANIMAL) rcr on (rcr.codigo_animal = a.codigo_animal)
left join 
   SP_NIVEL_LAB(1,0, a.CODIGO_NIVEL_LAB, a.CODIGO_ANIMAL) NL on (NL.CHAVE_OUT = A.CODIGO_ANIMAL)
left join racas r on (r.codigo_raca = a.codigo_raca)
left join localidades loc on (loc.codigo_localidade = a.codigo_localidade)
left join animais am on (am.codigo_animal = a.codigo_mae)
left join animais amvp on (amvp.codigo_animal = am.codigo_pai)
left join animais ap on (ap.codigo_animal = a.codigo_pai)
Where (a.codigo_fazenda > 0) and (F.CONSIDERAR_ESTOQUE = 1) and (F.CONSIDERAR_FAZENDA = 1) 
  and (a.plantel = 1)
   and (A.CODIGO_ANIMAL = NL.CHAVE_OUT)
 and ( ( (
 (A.SEXO = 0) 
 and (A.FASE_CUP = 0 or A.FASE_CUP = 1 or A.FASE_CUP is null) 
 and ( 
 (A.TIPO = 9) 
 or (A.TIPO = 0) 
 or (A.TIPO = 1) 
 or (A.TIPO = 2) 
 or (A.TIPO = 3) 
 ) ) and ( 
 (A.SEXO = 0) and ( 
 (A.SITUACAO =10) 
 or (A.SITUACAO = 0) 
 or (A.SITUACAO = 1) 
 or (A.SITUACAO = 2) 
 ) ) ) 
 or 
 ( ( (A.SEXO = 1) and ( 
 (A.TIPO = 9) 
 or (A.TIPO = 0) 
 or (A.TIPO = 1) 
 or (A.TIPO = 3) 
 ) ) and 
 ( (A.SEXO = 1) and ( 
 (A.SITUACAO = 10) 
 or (A.SITUACAO = 0) 
 ) ) ) 
  ) 
into :cod_animal, :sex_animal, :tip_animal, :v_sit, :v_data_nasc, :nome_usual_serie, :nome_usual_numero, :dias_situacao, :dias_abate, :dias_certificacao, :data_saida, :vCategoria_Femea, :nome_usual, :raca, :tipo_grau, :data_nascimento, :localidade, :inventario, :avo_materno, :avo_materno_serie, :avo_materno_numero, :Categoria_ERP, :pai, :pai_serie, :pai_numero, :mae, :mae_serie, :mae_numero
   do
   begin
      formato = '';
      formato = '';
      if (sex_animal = 0) then
           sexo= 'F';
      if (sex_animal = 1) then
           sexo= 'M';
      formato = '';
      formato = '';
      formato = '';
      formato = '';
      if (sex_animal = 0) then
      begin
        if (tip_animal = 0) then
           tipo= 'Reprodução';
        if (tip_animal = 1) then
           tipo= 'Doadora';
        if (tip_animal = 2) then
           tipo= 'Receptora';
        if (tip_animal = 3) then
           tipo= 'Engorda';
      end
      if (sex_animal = 1) then
      begin
        if (tip_animal = 0) then
           tipo= 'Reprodutor';
        if (tip_animal = 1) then
           tipo= 'Reprodutor/Sêmen';
        if (tip_animal = 2) then
           tipo= 'Sêmen';
        if (tip_animal = 3) then
           tipo= 'Engorda';
        if (tip_animal = 4) then
           tipo= 'Touro Múltiplo';
      end
      formato = '';
      formato = '';
      formato = '';
      formato = '';
      formato = '';
      formato = '';
      if (sex_animal = 0) then
      begin
        if (v_sit = 0) then
           str_situacao = 'Vazia';
        if (v_sit = 1) then
           str_situacao = 'Servida';
        if (v_sit = 2) then
           str_situacao = 'Gestante';
        if (v_sit = 3) then
           str_situacao = 'Parida';
        if (v_sit = 4) then
           str_situacao = 'Vendida';
        if (v_sit = 5) then
           str_situacao = 'Morta';
        if (v_sit = 6) then
           str_situacao = 'Doada';
        if (v_sit = 7) then
           str_situacao = 'Emprestada';
        if (v_sit = 8) then
           str_situacao = 'Devolvida';
        if (v_sit = 9) then
           str_situacao = 'Ajuste Inventário';
      end
      if (sex_animal = 1) then
      begin
        if (v_sit = 0) then
           str_situacao = 'Ativo';
        if (v_sit = 4) then
           str_situacao = 'Vendido';
        if (v_sit = 5) then
           str_situacao = 'Morto';
        if (v_sit = 6) then
           str_situacao = 'Doado';
        if (v_sit = 7) then
           str_situacao = 'Emprestado';
        if (v_sit = 8) then
           str_situacao = 'Devolvido';
        if (v_sit = 9) then
           str_situacao = 'Ajuste Inventário';
      end
     codigo_animal = cod_animal;
     suspend;
nome_usual = null; 
sexo = null; 
raca = null; 
tipo_grau = null; 
data_nascimento = null; 
tipo = null; 
localidade = null; 
inventario = null; 
avo_materno = null; 
Categoria_ERP = null; 
pai = null; 
mae = null; 
   end
END
 

^
SET TERM ; ^

