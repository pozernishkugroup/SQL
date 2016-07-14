select ao.ID
, ao.ADORDERNUMBER
, ar.AMOUNT
, dbu.BEANTYPE
, ai.ADTYPEID
, ai.PRODMETHODID
, prod.NAME as PRODUCT
, ap.ISONLINEPRODUCT

, (SELECT DISTINCT dabn.NAME
FROM DATABEANUSE duse
JOIN DATABEAN dabn ON duse.ROOTID = dabn.ROOTID
WHERE RUNSCHEDULEID = dbu.RUNSCHEDULEID AND BEANTYPE = 'dfp_section') SECT

, (SELECT DISTINCT dabn.NAME
FROM DATABEANUSE duse
JOIN DATABEAN dabn ON duse.ROOTID = dabn.ROOTID
WHERE RUNSCHEDULEID = dbu.RUNSCHEDULEID AND BEANTYPE = 'dfp_site') SITE

, (SELECT dabn.NAME
FROM DATABEANUSE duse
JOIN DATABEAN dabn ON duse.ROOTID = dabn.ROOTID
WHERE RUNSCHEDULEID = dbu.RUNSCHEDULEID AND (BEANTYPE = 'localedge_Bundle' OR BEANTYPE = 'localedge_Product')) BundleSubProduct

, extractvalue(xmltype(shd.BLOBDATA, 1), '/booked-order/ads[id=' || ai.ID || ']/online-content[name="unit"]/value') UNIT
, extractvalue(xmltype(shd.BLOBDATA, 1), '/booked-order/ads[id=' || ai.ID || ']/online-content[name="quantity"]/value') QUANTITY
, sscat.NAME CATEGORY
, extractvalue(xmltype(shd.BLOBDATA, 1), '/booked-order/ads[id=' || ai.ID || ']/online-content[name="page"]/value') NUMBEROFPAGES
, posn.name POSITION

, to_char(ar.EFFECTIVEDATE, 'MM/dd/yyyy') as EFFECTIVEDATE

, CASE 
WHEN SUBSTR(dbf_runschedule_startdate (rs.id), -5) = SUBSTR(dbf_runschedule_enddate (rs.id), -5)
THEN dbf_runschedule_enddate (rs.id)
WHEN SUBSTR(ar.EFFECTIVEDATE, -5) = SUBSTR(dbf_runschedule_enddate (rs.id), -5)
THEN dbf_runschedule_enddate (rs.id)
ELSE ar.billingdate END line_end_date

, rs.SORTTEXT

, dbf_runschedule_startdate(rs.id) RSSTARTDATE
, dbf_runschedule_enddate (rs.id) RSENDDATE

, (SELECT NETWORKVALUENAMES FROM NRA
WHERE ORDERID = ao.id AND NETWORKATTRIBUTEID = (select id from networkattributes where attributename = 'caption' and networkid = 
      (select id from adnetworks where name = 'ORDER'))) CAPT

, nra.networkvaluenames
, to_char(ao.CREATEDATE, 'MM/dd/yyyy') as CREATEDATE
, to_char(aord.STARTDATE, 'MM/dd/yyyy') as STARTDATE
, to_char(aord.ENDDATE, 'MM/dd/yyyy') as ENDDATE
, c.NAME2 || ' ' || c.NAME1 as NAME
, c.CAMPANYNAME2 as COMPANY_NAME 
, c.accountnumber
, l.ADDRESS1, l.ADDRESS2, l.CITY, l.state, l.POSTALCODE, l.COUNTRY
, st.STATENAME_A
, u.USERFNAME || ' ' || u.USERLNAME as SALESREP 

, shc.name AS company_code
, AOORDER.PONUMBER as PurchaseOrder
-- , aoud.NUMCOLUMNS
-- , aoud.DEPTH
, aoud.NAME SIZEFORLOCALCOM
, aoud.NAME || ' ' || aoud.NUMCOLUMNS || ' x ' || aoud.DEPTH || ' px ' || clr.NAME as ADSIZEUNIT
, aac.NUMCOLUMNS
, to_char(aac.ADDEPTH/1440, 'FM999999.99') as DEPTH
,( 
select valueid from nravalues where nraid=( 
select id from nra where customerid = c.ACCOUNTID and networkattributeid = (select id from networkattributes where attributename = 'tearsheet' and networkid = (select id from adnetworks where name = 'CUSTOMER')) 
) 
) Tearsheetflag 


FROM ARTRANSACTIONS ar 
join AOADORDER ao on ar.ORDERID=ao.ID
join RTCHARGEENTRYELEM rtc on ar.RTCHARGEENTRYELEMID=rtc.ID
join AOADRUNSCHEDULE rs on rtc.ADRUNSCHEDULEID=rs.ID
LEFT join AOADRUNDATES aord ON rs.id=aord.ADRUNSCHEDULEID
join AOADCONTENT aac on rtc.ADCONTENTID=aac.ID
join AOADINFO ai on aac.ADINFOID=ai.ID
join customer c on ar.CUSTOMERID=c.ACCOUNTID
join location l on c.accountid = l.customerid
left join statename st on st.STATEID=c.PRIMARYSTATEID
join usrusers u on ar.SALESREPID=u.USERID
join AOPRODUCTS prod on rs.PRODUCTID=prod.ID
join AoProductDef ap ON rs.ProductID = ap.ProductID and prod.ID = ap.PRODUCTID
join shcompanies shc ON ap.companyid = shc.id
INNER JOIN AOORDERCUSTOMERS AOORDER ON rs.ADORDERID = AOORDER.ADORDERID
LEFT join aouserunitdefs aoud ON aac.userunitid = aoud.id
LEFT JOIN AoColors clr ON clr.ID = aac.COLORTYPEID
LEFT JOIN AoAdPositions posn ON posn.ID = rs.POSITIONID
LEFT JOIN DATABEANUSE dbu ON dbu.RUNSCHEDULEID = rtc.ADRUNSCHEDULEID
LEFT JOIN DATABEAN bea ON bea.ROOTID = dbu.ROOTID

join nra on nra.id=( 
  select id from nra where orderid = ao.ID and networkattributeid = 
    (select id from networkattributes where attributename = 'salesdesk' and networkid = 
      (select id from adnetworks where name = 'CUSTOMER')
    )
)

JOIN SHEXTERNALDOCUMENT she ON she.ADORDERID = ao.ID
JOIN SHBLOBDATA shd ON shd.ID = she.CONTENTBLOBID
JOIN SS_ADRUNSCHEDULE ssrs ON ssrs.RUNSCHEDULEID = rs.ID
LEFT JOIN SS_CATEGORIES sscat ON sscat.ID = ssrs.CATEGORYID

WHERE ao.ADORDERNUMBER = @AdOrderNumber_Param
AND (dbu.BEANTYPE = 'digitalFormMappings.scheduleFormState' OR dbu.BEANTYPE = 'digitalFormMappings.classifiedFormState' OR dbu.BEANTYPE IS NULL)
AND bea.DELETEDBY IS NULL
AND RS.ADORDERID = ao.ID
AND l.primary=1
order by ai.ADTYPEID, ar.EFFECTIVEDATE