// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@chainlink/contracts@1.2.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./AggregatorV3Interface.sol";
import "./PriceConverter.sol";
// import "@PatrickAlphaC/fund-me-fcc/PriceConverter.sol";

// import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

//Estamos importando del repositorio de npm de @Chainlink/contracts
//Podria reemplazar el import por todo el codigo del repositorio y funcionaria todo igual
//En el repositorio, todas las funciones solo estan declaradas, no tienen ninguna operacion dentro
//Las interfaces se compilan hasta la ABI

//Contrato para que puedan financiar mi proyecto
contract FundMe {
    using PriceConverter for uint256;
    //Para evitar Overflow
    //Usar el Safemath para todoslos uint256
    //Using se usa para usar las fuciones de otro contrato en este
    // using SafeMathChainlink for uint256;

    //Relacionar la direccion con el dinero que me envia
    //addressToAmountFunded es el nombre de la funcion
    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    AggregatorV3Interface public priceFeed; // Creamos esto para poder acceder al precio desde un entorno local

    //Contructores: codigo que se ejecuta despues de que el contrato es desplegado y se hace de forma automatica
    //Que el owner pase a ser quien ejecuta este contrato
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    //Funcion que me permita recibir dinero
    function fund() public payable {
        //Establecer un minimo para enviar
        uint256 minimumUSD = 1 * 10 ** 18;

        //Se podria hacer asi
        //if (msg.value < minimumUSD) {
        //    revert();
        //}

        //o mejor con Require: permite establecer un parametro para que se ejecute la funcion
        //necesitoque el ratio de conversion del valor que esta en el mensaje sea mayor que minimo
        //Sepuede poner un mensaje si no se cumple
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more eth"
        );

        //Llevar registro de quienes nos envian el dinero (msg.value y msg.sender)
        //A partir de la direccion, veo cuando envio
        addressToAmountFunded[msg.sender] += msg.value;

        //Para establecer un minimo que se puede enviar y la conversion de una moneda a otra
        //Se usan los oraculos para traer informacion del mundo real a la blockchain

        //Guardamos las direcciones de todos los que nos enviamos dinero
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //debemos definir la interfaz:
        //Paso como parametro la direccion a donde me va a devolver estos datos
        //La direccion es la que proporciona docs.chainlink Eth prices feed, para el par eth/usd de la red sepolia
        //Estamos haciendo referencia a un contrato desplegado en esta direccion para recuperar el precio

        //Ya no necesito esto:
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x694AA1769357215DE4FAC081bf1f309aDC325306
        //);
        return priceFeed.version();
    }

    //Pero necesitamos acceder a la funcion lastestRoundData() para acceder al int256 answer, que es donde esta la tasa de cambio de las dos divisas que necesitamos

    function getPrice() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x694AA1769357215DE4FAC081bf1f309aDC325306
        //);
        //creamos una Tupla: es una lista de elementos que pueden ser diferentes. Una vez creada, ya no se pueden agregar mas elementos
        //Tener el codigo asi nos da una alerta porque hay variables que no estoy usando
        //(uint256 roundID,
        //int price,
        //uint startedAt,
        //uint timeStamp,
        //uint80 answeredInRound) = priceFeed.latestRoundData();

        //Se puede corregir borrando y dejando el espacio de las variables  que no uso:
        (, int price, , , ) = priceFeed.latestRoundData();
        //Data Casting: transformar algunos tipos de datos en otros. Señalo que tipo de dato quiero y paso entre () el valor
        //multiplicamos para que convertir el precio a USD, aunque esto gasta mas gas
        return uint256(price * 10000000000);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 5 * 10 ** 1;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 * 18;
        return ((minimumUSD * precision) / price) + 10000000000000000;
    }

    // Cada vez que modifico el contrato hay que compilarlo

    function getConversionRate(
        uint256 ethAmount
    ) public view returns (uint256) {
        //Obtenemos el precio de eth y lo guardamos en la variable
        uint256 ethPrice = getPrice();
        //Multiplicamos la cantidad de eth por el precio. La cantidad se debe pasar en unidades de wei
        //Para que esto se rija en estandares de 18 decimales, lo dividimos por 10^18 porque antes lo habiamos multiplicado por 10^10
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    //Transfer: es una funcion nativa para todas las address nativas de eth y nos permite trnasferir activos de una billetera a otra
    //This hace referencia a todo lo que esta dentro de este contrato
    //Al que me envia este mensaje es al que le vamos a transferir desde este contrato (por eso le pasamos la direccion de este contrato
    //Balance devuelve todos los activos de este contrato por lo que se transferiran todos los activos
    //Con la funcion fund le mandamos plata al contrato y con withdrow se puede sacar a una billetera
    //Tenemos que hacer que solo el dueño pueda invocar esta funcion y sacar los fondos
    //Usamos modificadores: para cambiar como se comporta una funcion y lo hacemos de forma declarativa (lo declaramos nosotros)
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; //esto significa que aca va a ejecutar el resto del codigo
    }

    //Agrego el modificador onlyOwner
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        //For Loop: crea un bucle a traves de un rango para que algo ocurra en cada repeticion del bucle
        for (uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
            //dentro del mapping, en la ubicacion de la address funder, la convierte a 0 para borrarla
        }
        funders = new address[](0);
    }

    //--------------------------------
    //Overflows o Underflows (en versiones superiores a 0.8.0, nsolidity hace una verificacion automatica para evitar esto)
    //Cuando sobrepasamos los 256 caracteres de limite, vuelve al valor 0 si agregamos un valor mas

    //Haremos uso de una libreria para evitar incurrir en los Overflows
}

// Para crear el entorno virtual de desarrollo tengo que ejecutar en la terminal source ../brownieProjects/bin/activate

// FORKING: hacer una indentacion de una blockchain existente para poder interacutar algunos de los priceFeed que ya esten desplegados. Crea una copia de una blockchain en nuestro entorno local par apoder interactuar. Brownie ya viene con una integracion de la mainnet fork que se conecta y trabaja con infura.
// Mocking: hacer un simulacro, de crear un priceFeed en nuestro ambito local de ganache
// Patron de Mock: es muy comun en programacion, es crear versiones falsas de algun componente, para hacer pruebas

// Alchemy es otro servicio donde se puede usar la mainnet-fork y es añadiendo una nueva red
// Crear network ejecutando: brownie networks add development mainnet-fork-dev cmd=ganache-cli host=http://127.0.0.1 fork=https://eth-mainnet.g.alchemy.com/v2/Gc7fTeiIEhxvBn2qwFoeYvwHmaGZpTNs accounts=10 mnemonic=brownie port=8545
// cmd es el comand line
// El host esta dentro de nuestro localhost
// El fork lo toma desde Alchemy: Dentro de mi APP creada, busco el enlace de HTTPs de la red de ETH Mainnet
// Accounts: numero de cuentas que va a tener
