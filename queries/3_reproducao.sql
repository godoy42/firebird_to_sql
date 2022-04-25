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
    ULT_ACASALA_PARTO varchar(15),
    RESULTADO_PARTO varchar(100),
    ULTIMO_PARTO date,
    SITUACAO varchar(20),
    DATA_PREV_PARTO date,
    CATEGORIA_ERP varchar(30),
    ULTIMA_COBERTURA date,
    DATA_DG date,
    RESULTADO_DG varchar(20) )

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
   Declare variable v_ult_acasala_parto varchar(015);
   Declare variable v_result_parto varchar(100);
   Declare variable v_data_ult_parto date;
   Declare variable v_situacao varchar(020);
   Declare variable v_dt_prev_parto date;
   Declare variable vCatERP varchar(030);
   Declare variable v_data_ult_cober date;
   Declare variable vDATA_DG date;
   Declare variable vRes_DG varchar(020);
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
,    case 
      when (a.situacao = 1 or a.situacao = 2) then 
           ( select 
                first 1 
                cpp.data_cobertura + scg.medio_gestacao 
             from 
                coberturas cpp 
             left join 
                SP_CALC_GESTACAO(case 
                                    when cpp.codigo_cobertura is null then -3 
                                    when cpp.codigo_doadora is not null then cpp.codigo_doadora 
                                    when cpp.CODIGO_FEMEA is not null then cpp.codigo_femea 
                                    else -3 
                                 end, 
                                 case 
                                    when cpp.codigo_cobertura is null then -3 
                                    when cpp.CODIGO_MACHO is not null then cpp.codigo_macho 
                                    else -3 
                                 end) SCG on (scg.minimo_gestacao is not null) 
             where 
                cpp.nparto = a.nparto 
                and cpp.codigo_femea = a.codigo_animal 
                and cpp.situacao in (1,2) 
           )
   end 
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
, ( select        case           when c.data_exame2 is not null then c.data_exame2           else c.data_exame        end     from        coberturas c     where        (c.codigo_cobertura = ( select                                   first 1                                      c1.codigo_cobertura                                   from                                      coberturas c1                                   where                                     (c1.codigo_femea = a.codigo_animal) and                                     (c1.data_exame2 is not null or c1.data_exame is not null )                                    order by                                      c1.data_cobertura desc ,c1.data_exame2 desc,c1.data_exame                              )        )   ) as data_dg 
, ( select        case           when c.data_exame2 is not null then            case              when c.resultado_exame2 = 0 then 'Pos'             when c.resultado_exame2 = 1 then 'Neg'             when c.resultado_exame2 = 2 then 'Dúv'             else ''          end           when (c.data_exame2 is null) and (c.data_exame is not null) then            case              when c.resultado_exame = 0 then 'Pos'             when c.resultado_exame = 1 then 'Neg'             when c.resultado_exame = 2 then 'Dúv'             else ''          end           else ''       end     from        coberturas c     where        (c.codigo_cobertura = ( select                                   first 1                                      c1.codigo_cobertura                                   from                                      coberturas c1                                   where                                      (c1.codigo_femea = a.codigo_animal) and                                     (c1.data_exame2 is not null or c1.data_exame is not null )                                   order by                                     c1.data_cobertura desc ,c1.data_exame2 desc,c1.data_exame                              )        )   ) as resultado_dg 
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
into :cod_animal, :sex_animal, :tip_animal, :v_sit, :v_data_nasc, :nome_usual_serie, :nome_usual_numero, :dias_situacao, :dias_abate, :dias_certificacao, :data_saida, :vCategoria_Femea, :nome_usual, :data_prev_parto, :Categoria_ERP, :DATA_DG, :Resultado_DG
   do
   begin
      formato = '';
      formato = '';
      if (sex_animal = 0) then
      begin
        select macho from ret_ult_cober(:cod_animal, 287, 2)
          into :ult_acasala_parto;
      end
      if (sex_animal = 1) then
      begin
        select femea from ret_ult_cober(:cod_animal, 287, 2)
          into :ult_acasala_parto;
      end
      formato = '';
       select
          list(resultado, ' | ') as resultado
       from
       (
         select
            case
               when c.tipo_parto <= 3 then
                  case
                     when ( (cr.codigo_animal > 0) and (cr.sexo = 0) ) then 'F' || ' ' || cr.nome_usual ||  case   when cr.situacao = 0 then ' /Vaz'  when cr.situacao = 1 then ' /Ser'  when cr.situacao = 2 then ' /Ges'  when cr.situacao = 3 then ' /Par'  when cr.situacao = 4 then ' /Ven'  when cr.situacao = 5 then ' /Mor'  when cr.situacao = 6 then ' /Doa'  when cr.situacao = 7 then ' /Emp'  when cr.situacao = 8 then ' /Dev'  when cr.situacao = 9 then ' /Aju' end 
                     when ( (cr.codigo_animal > 0) and (cr.sexo = 1) ) then 'M' || ' ' || cr.nome_usual ||  case   when cr.situacao = 0 then ' /Ati'  when cr.situacao = 4 then ' /Ven'  when cr.situacao = 5 then ' /Mor'  when cr.situacao = 6 then ' /Doa'  when cr.situacao = 7 then ' /Emp'  when cr.situacao = 8 then ' /Dev'  when cr.situacao = 9 then ' /Aju' end 
                     when p.situacao_cria1 = 1 then 'Natimorto'
                     when p.situacao_cria1 = 2 then 'Descartado'
                     when p.status_crias = 2 then 'Dados da cria não informados'
                  end
               when c.tipo_parto = 4 then 'Aborto'
               when c.tipo_parto = 5 then 'M. Embrionária'
               when c.tipo_parto = 6 then 'Coletada'
            end as resultado
         from
            coberturas c
         left join
            partos p on (p.codigo_cobertura = c.codigo_cobertura)
         left join
            animais cr on (cr.codigo_animal in (p.codigo_cria1, p.codigo_cria2, p.codigo_cria3, p.codigo_cria4, p.codigo_cria5))
         where
            (c.codigo_femea = :cod_animal or c.codigo_macho = :cod_animal) and
            (c.situacao = 3)
            and (p.codigo_parto = (select
                                      first 1
                                      p1.codigo_parto
                                   from
                                      partos p1
                                   left join
                                      coberturas c1 on c1.codigo_cobertura = p1.codigo_cobertura
                                   where
                                      (c1.codigo_femea = :cod_animal or c1.codigo_macho = :cod_animal)
                                   order by
                                      p1.data_parto desc
                                  )
                )
         order by
            c.data_cobertura desc
         )
         into :resultado_parto;
      formato = '';
      if (sex_animal = 0) then
      begin
        select max(data_parto) from partos
         where codigo_femea = :cod_animal
          into :ultimo_parto;
      end
      if (sex_animal = 1) then
      begin
        select max(p.data_parto) from coberturas c
         left join partos p on (p.codigo_cobertura = c.codigo_cobertura)
         where c.codigo_macho = :cod_animal
          into :ultimo_parto;
      end
      formato = '';
      if (sex_animal = 0) then
      begin
        if (v_sit = 0) then
           situacao= 'Vazia';
        if (v_sit = 1) then
           situacao= 'Servida';
        if (v_sit = 2) then
           situacao= 'Gestante';
        if (v_sit = 3) then
           situacao= 'Parida';
        if (v_sit = 4) then
           situacao= 'Vendida';
        if (v_sit = 5) then
           situacao= 'Morta';
        if (v_sit = 6) then
           situacao= 'Doada';
        if (v_sit = 7) then
           situacao= 'Emprestada';
        if (v_sit = 8) then
           situacao= 'Devolvida';
      end
      if (sex_animal = 1) then
      begin
        if (v_sit = 0) then
           situacao= 'Ativo';
        if (v_sit = 4) then
           situacao= 'Vendido';
        if (v_sit = 5) then
           situacao= 'Morto';
        if (v_sit = 6) then
           situacao= 'Doado';
        if (v_sit = 7) then
           situacao= 'Emprestado';
        if (v_sit = 8) then
           situacao= 'Devolvido';
      end
      formato = '';
      formato = '';
      formato = 'dd/mm/yyyy';
      select data from ret_ult_cober(:cod_animal, 287, 0)
        into :ultima_cobertura;
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
ult_acasala_parto = null; 
resultado_parto = null; 
ultimo_parto = null; 
situacao = null; 
data_prev_parto = null; 
Categoria_ERP = null; 
ultima_cobertura = null; 
DATA_DG = null; 
Resultado_DG = null; 
   end
END
 

^
SET TERM ; ^