//getElementByClassName => 배열로 리턴 [0]
const container = document.querySelector('.container');
console.log(container);
const printResult = document.getElementById('printResult');
let printValue = ''; // 최종 결과 string
let isResultShow = false; // = 이후 결과가 표시된 상태인지를 추적

container.addEventListener('click',(e)=>{
    console.log(e.target.value);
    let btnValue = e.target.value;
    
    // value가 없는 부분은 undefined 
    if(btnValue === undefined) return;

    // 숫자 isNaN => false
    console.log(isNaN(btnValue));
    if(!isNaN(btnValue)){
        // 계산 결과가 있는지 확인 변수
        if(isResultShow){
            // 결과 -> 새로운 계산시작
            printValue = btnValue;
            isResultShow = false;
        }else{
            // 결과X
            printValue += btnValue;
        }
    }else{
        // 숫자가 아닌 케이스 (+ - * / . = c)
        if(btnValue !== undefined){
            // 값이 비었을 경우 [] 안의 연산이 먼저 나오면 0으로 변경
            if(printValue == '' && ['+','-','*','/','.'].includes(btnValue)){
                printValue = '0';
                // return; 무시하려면 
            }
            switch(btnValue){
                case'c': 
                    // 변수 / 화면 초기화
                    printValue='';
                    printResult.innerText = '0';
                    return;
                
                case'.': 
                // 소수점 연속적 발생 방지
                    const parts = printValue.split(/[\+\-\*\/]/);
                    if(!parts.pop().includes('.')){
                        //기존 값에 붙이기
                        printValue += btnValue;
                    }
                break;
                default: 
                    let result = 0; // 연산의 결과를 받을 변수
                    
                    if(btnValue == '='){
                        // 계산하기
                        result = extractValue(printValue);
                        printValue = result;
                        isResultShow = true;
                    }else{
                        // + - * /  123 +  추가
                        // 연산자가 연속으로 두번 눌릴경우 
                        // 이전 연산자를 새 연산자로 교체
                        console.log(printValue);
                        
                        // 결과가 표시된 상태에서 연산자 -> 이어서 계산
                        if(isResultShow){
                            isResultShow = false;
                        }
                        
                        // 1. 마지막 문자가 연산자인지 확인
                        let trimmed = printValue.trim();
                        if(/[\+\-\*\/]$/.test(trimmed)){
                            // 2. 마지막 연산자를 새 연산자로 교체
                            printValue = trimmed.slice(0, -1) + btnValue + " " ;
                        }else{
                            // 일반적인 경우
                            printValue += ` ${btnValue} `;
                        }
                    }
                break;

            }
        }

    }

    printResult.innerText = printValue;
});

function operation(f, o, l){
    // f, l 은 number 형태로 들어와야 함.
    f = Number(f);
    l = Number(l);
    let result = 0;
    switch(o){
        case '+': result = f + l; break;
        case '-': result = f - l; break;
        case '*': result = f * l; break;
        case '/': 
            if(l == 0){
                alert('0으로 나눌 수 없습니다.');
                return 0;
            }
            result = f / l;
        break;
        default: break;
    }
    return result.toFixed(2);
}

function extractValue(strVal){
    // strValue = 123 + 456
    // substring(시작번지, 끝번지)
    // substr(시작번지, 개수)
    let firstNum = strVal.substring(0, strVal.indexOf(" "));
    let lastNum = strVal.substring(strVal.lastIndexOf(" ")+1);
    let op = strVal.substr(strVal.indexOf(" ")+1,1);
    console.log(firstNum);
    console.log(op);
    console.log(lastNum);
    return operation(firstNum, op, lastNum);
}