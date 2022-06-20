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
left join liberado_abate_sisbov(a.codigo_animal, NULL) las on (las.codigo_animal = a.codigo_animal)
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
