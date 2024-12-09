--cria pacote PKG_ALUNO
CREATE OR REPLACE PACKAGE PKG_ALUNO IS
	PROCEDURE exclui_aluno(
    	id_aluno IN NUMBER
    );
END PKG_ALUNO;
CREATE OR REPLACE PACKAGE BODY PKG_ALUNO IS
    --Procedure de exclusão de aluno:
	PROCEDURE exclui_aluno(
    	id_aluno IN NUMBER
    );
	BEGIN
        DELETE FROM Matricula
        WHERE Aluno.id_aluno = id_aluno;
        DELETE FROM Aluno
        WHERE Aluno.id_aluno = id_aluno
    END exclui_aluno;

	--Cursor de listagem de alunos maiores de 18 anos:
	DECLARE
        CURSOR maioridade IS
            SELECT nome, data_nascimento
            FROM Aluno
            WHERE (TRUNC(SYSDATE) - data_nascimento) / 365 > 18;

    	v_nome Aluno.nome%TYPE;
    	v_data_nascimento Aluno.data_nascimento%TYPE;
	BEGIN
        OPEN maioridade;
        LOOP
        	FETCH maioridade INTO v_nome, v_data_nascimento
        	EXIT WHEN maioridade%NOTFOUND;

			DBMS_OUTPUT.PUT_LINE('Nome: ' || v_nome || ', Data de Nascimento: ' || TO_CHAR(v_data_nascimento, 'DD/MM/YYYY'));
		END LOOP;
		CLOSE maioridade;
    END;

	--Cursor com filtro por curso:
	DECLARE
        CURSOR aluno_no_curso(p_id_curso NUMBER) IS
        SELECT a.nome
        FROM aluno a
        JOIN matricula m ON a.id_aluno = m.id_aluno
        JOIN disciplina d ON m.id_disciplina = d.id_disciplina
        WHERE d.id_curso = p_id_curso;

	v_nome VARCHAR2(50);
	BEGIN
    OPEN aluno_no_curso(1);

    LOOP
        FETCH aluno_no_curso INTO v_nome;
        EXIT WHEN aluno_no_curso%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Nome do Aluno: ' || v_nome);
    END LOOP;

    CLOSE aluno_no_curso;
END PKG_ALUNO;

CREATE OR REPLACE PACKAGE BODY PKG_DISCIPLINA IS
    --Procedure de cadastro de disciplina:
    CREATE OR REPLACE PROCEDURE cadastrar_disciplina(
    p_nome IN VARCHAR2,
    p_descricao IN VARCHAR2,
    p_carga_horaria IN NUMBER,
    )
    IS
    BEGIN
        INSERT INTO disciplina (nome, descricao, carga_horaria)
        VALUES (p_nome, p_descricao, p_carga_horaria);
        
        DBMS_OUTPUT.PUT_LINE('Disciplina cadastrada com sucesso: ' || p_nome);
    END cadastrar_disciplina;

	--Cursor para total de alunos por disciplina:
	DECLARE
    CURSOR disciplina10 IS
        SELECT d.nome AS nome_disciplina,
               COUNT(m.id_aluno) AS total_alunos
        FROM Disciplina d
        LEFT JOIN Matricula m ON d.id_disciplina = m.id_disciplina
        GROUP BY d.nome
        HAVING COUNT(m.id_aluno) > 10;

    v_nome_disciplina Disciplina.nome%TYPE;
    v_total_alunos NUMBER;
	BEGIN
        OPEN disciplina10;
    
        LOOP
            FETCH disciplina10 INTO v_nome_disciplina, v_total_alunos;
            EXIT WHEN disciplina10%NOTFOUND;
    
            DBMS_OUTPUT.PUT_LINE('Disciplina: ' || v_nome_disciplina || ' - Total de Alunos: ' || v_total_alunos);
        END LOOP;
    
        CLOSE disciplina10;
    END;

	--Cursor com média de idade por disciplina:
	DECLARE
        CURSOR idade_media(p_id_disciplina IN NUMBER) IS
            SELECT AVG((TRUNC(SYSDATE) - data_nascimento) / 365) AS media_idade
            FROM Aluno a
            JOIN Matricula m ON a.id_aluno = m.id_aluno
            WHERE m.id_disciplina = p_id_disciplina;
    
        v_media_idade NUMBER;
    BEGIN
        OPEN idade_media(1);
    
        FETCH idade_media INTO v_media_idade;
        EXIT WHEN idade_media%NOTFOUND;
    
        IF v_media_idade IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Média de Idade dos Alunos: ' || ROUND(v_media_idade, 2) || ' anos');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Nenhum aluno matriculado na disciplina especificada.');
        END IF;
    
        CLOSE idade_media;
    END;

	--Procedure para listar alunos de uma disciplina:
	CREATE OR REPLACE PROCEDURE listar_alunos_disciplina(p_id_disciplina IN NUMBER) AS
        CURSOR alunos_na_disciplina IS
            SELECT a.nome
            FROM Aluno a
            JOIN Matricula m ON a.id_aluno = m.id_aluno
            WHERE m.id_disciplina = p_id_disciplina;
    
        v_nome Aluno.nome%TYPE;
    BEGIN
        OPEN alunos_na_disciplina;
    
        LOOP
            FETCH alunos_na_disciplina INTO v_nome;
            EXIT WHEN alunos_na_disciplina%NOTFOUND;
    
            DBMS_OUTPUT.PUT_LINE('Aluno: ' || v_nome);
        END LOOP;
    
        CLOSE alunos_na_disciplina;
	END listar_alunos_disciplina;
END PKG_DISCIPLINA;

--cria pacote PKG_PROFESSOR
CREATE OR REPLACE PACKAGE PKG_PROFESSOR IS
	FUNCTION total_turma(
    	id_professor IN NUMBER
    );
	FUNCTION professor_da_disciplina(
        id_disciplina IN NUMBER
    );
END PKG_PROFESSOR;
CREATE OR REPLACE PACKAGE BODY PKG_PROFESSOR IS
	DECLARE
    CURSOR professor_turma IS
        SELECT p.nome AS nome_professor,
               COUNT(t.id_turma) AS total_turmas
        FROM Professor p
        JOIN Turma t ON p.id_professor = t.id_professor
        GROUP BY p.nome
        HAVING COUNT(t.id_turma) > 1;

    v_nome_professor Professor.nome%TYPE;
    v_total_turmas NUMBER;
    BEGIN
        OPEN professor_turma;
    
        LOOP
            FETCH professor_turma INTO v_nome_professor, v_total_turmas;
            EXIT WHEN professor_turma%NOTFOUND;
    
            DBMS_OUTPUT.PUT_LINE('Professor: ' || v_nome_professor || ' - Total de Turmas: ' || v_total_turmas);
        END LOOP;
    
        CLOSE professor_turma;
    END;
	--Function para total de turmas de um professor:
	CREATE OR REPLACE FUNCTION total_turma(p_id_professor IN NUMBER) 
    RETURN NUMBER AS
        v_total_turmas NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total_turmas
        FROM Turma
        WHERE id_professor = p_id_professor;
    
        RETURN v_total_turmas;
    END total_turma;

	--Function para professor de uma disciplina:
	CREATE OR REPLACE FUNCTION professor_da_disciplina(p_id_disciplina IN NUMBER)
    RETURN VARCHAR2 AS
        v_nome_professor Professor.nome%TYPE;
    BEGIN
        SELECT p.nome
        INTO v_nome_professor
        FROM Professor p
        JOIN Disciplina d ON p.id_professor = d.id_professor
        WHERE d.id_disciplina = p_id_disciplina;
    
        RETURN v_nome_professor;
    END professor_da_disciplina;
END PKG_PROFESSOR;