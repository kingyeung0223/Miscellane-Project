-- A user-defined table-value function
ALTER FUNCTION [dbo].[GetOpenEndAnswer]
(	
	-- Add the parameters for the function here
	@SurveyId as uniqueidentifier,
	@QuestionJsPath as nvarchar(max)
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	select JSON_VALUE(a.AnswerJS, '$.staffNo') as Respondent, JSON_VALUE(a.AnswerJS, @QuestionJsPath) as OpenEndAnswer
	from dbo.SurveyAnswer a
	where a.SurveyId = @SurveyId
)


-- A user-defined table-value function
ALTER FUNCTION [dbo].[GetMC_AnswerAsUnpivotTrueFalseMatrix]
(	
	-- Add the parameters for the function here
	@SurveyId as uniqueidentifier,
	@QuestionJsPath as nvarchar(max)
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	select JSON_VALUE(a.AnswerJS, '$.staffNo') as Respondent, dbo.RemoveBadStringInMC_Choice(q.AvailableChoice) as AvailableChoice, cast(q.IsSelected as tinyint) as IsSelected, q.Remarks, q.ChoiceBasedFollowUp
	from dbo.SurveyAnswer a
	cross apply openjson(a.AnswerJS, @QuestionJsPath)
	with 
		(
			AvailableChoice nvarchar(max) '$.value',
			IsSelected bit '$.selected',
			Remarks nvarchar(max) '$.remarks',
			ChoiceBasedFollowUp nvarchar(max) '$.options' as json
		)
	as q
	where a.SurveyId = @SurveyId
)


-- A user-defined scalar function
ALTER FUNCTION [dbo].[RemoveBadStringInMC_Choice]
(
	-- Add the parameters for the function here
	@text nvarchar(100)
)
RETURNS nvarchar(100)
AS
BEGIN
	declare @badStrings table (BadString nvarchar(50));
	declare @CleanedStr as nvarchar(100);

	INSERT INTO @badStrings(BadString)
	SELECT '>' UNION ALL
	SELECT '<' UNION ALL
	SELECT '(' UNION ALL
	SELECT ')' UNION ALL
	SELECT ',' UNION ALL
	SELECT '.' UNION ALL
	SELECT '?' UNION ALL
	SELECT '-' UNION ALL
	SELECT ':' UNION ALL
	SELECT ';' UNION ALL
	SELECT '''' UNION ALL
	SELECT '"' UNION ALL
	SELECT '{' UNION ALL
	SELECT '}' UNION ALL
	SELECT '[' UNION ALL
	SELECT ']' UNION ALL
	SELECT '\' UNION ALL
	SELECT '|' UNION ALL
	SELECT '/' UNION ALL
	SELECT '！' UNION ALL
	SELECT '#' UNION ALL
	SELECT '$' UNION ALL
	SELECT '%' UNION ALL
	SELECT '^' UNION ALL
	SELECT '&' UNION ALL
	SELECT '*' UNION ALL
	SELECT '=' UNION ALL
	SELECT '+' UNION ALL
	SELECT ' ' UNION ALL
	SELECT '+' UNION ALL
	SELECT N'　' UNION ALL
	SELECT N'，' UNION ALL
	SELECT N'。' UNION ALL
	SELECT N'：' UNION ALL
	SELECT N'—' UNION ALL
	SELECT N'（' UNION ALL
	SELECT N'）' UNION ALL
	SELECT N'；' UNION ALL
	SELECT N'？' UNION ALL
	SELECT N'！' UNION ALL
	SELECT N'、' UNION ALL
	SELECT '@'

	select @CleanedStr = @text
	SELECT @CleanedStr = Replace(@CleanedStr, BadString, '_') FROM @badStrings

	while PATINDEX('%[_][_]%', @CleanedStr) <> 0
		begin
			SELECT @CleanedStr = Replace(@CleanedStr, '__', '_')
		end
	
	if PATINDEX('%[0-9]%', @CleanedStr) = 1
		select @CleanedStr = '_' + @CleanedStr

	return @CleanedStr
END