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
    GANHO_FASE float,
    DATA_ULT_CE date,
    DATA_PULT_PESO date,
    ULTIMO_PESO float,
    ULTIMO_CE float )

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
   Declare variable v_ganho_fase float;
   Declare variable v_data_ult_ce date;
   Declare variable v_data_pult_peso date;
   Declare variable v_ultimo_peso float;
   Declare variable v_ultimo_ce float;
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
into :cod_animal, :sex_animal, :tip_animal, :v_sit, :v_data_nasc, :nome_usual_serie, :nome_usual_numero, :dias_situacao, :dias_abate, :dias_certificacao, :data_saida, :vCategoria_Femea, :nome_usual
   do
   begin
      formato = '';
      formato = '';
        select ganho_fase from dados_ult_pesagem(:cod_animal, 287)
          into :ganho_fase;
      formato = '';
        select first 1 ma.data from medicoes_animais ma where ma.codigo_animal = :cod_animal and ma.codigo_medicao = 3 order by ma.data desc
          into :data_ult_ce;
      formato = '';
        select first 1 skip 1 ma.data from medicoes_animais ma where ma.codigo_animal = :cod_animal and ma.codigo_medicao = 1 order by ma.data desc
          into :data_pult_peso;
      formato = '0.00';
        select peso from dados_ult_pesagem(:cod_animal, 287)
          into :ultimo_peso;
      formato = '';
        select first 1 ma.valor from medicoes_animais ma where ma.codigo_animal = :cod_animal and ma.codigo_medicao = 3 order by ma.data desc
          into :ultimo_ce;
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
ganho_fase = null; 
data_ult_ce = null; 
data_pult_peso = null; 
ultimo_peso = null; 
ultimo_ce = null; 
   end
END
 

^
SET TERM ; ^
