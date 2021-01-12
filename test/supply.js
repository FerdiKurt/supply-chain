const SupplyChain = artifacts.require('SupplyChain.sol')
const { expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

function toBN(arg) {
    return web3.utils.toBN(arg)
}

function toWEI(arg) {
    return web3.utils.toWei(arg)
}

contract('Supply Chain', accounts => {
    let supplyChain

    let identifier = '0x8bfc44ce4abf41b645f9a486647a42fecefc3462228f4bd51110435eeff3013b'
    let description = 'Item 1 '
    let price = toWEI('1', 'ether')

    before(async () => {
        supplyChain = await SupplyChain.new()
    })

    it('should NOT ADD item if not admin', async () => {
        await expectRevert(
            supplyChain.addItem(
                identifier,
                description,
                10,
                price,
                { from: accounts[1] }
            ),
            'Only owner!'
        )
    })

    it('should ADD an item', async () => {
        const _addItem = await supplyChain.addItem(
            identifier,
            description,
            10,
            price
        )

        expectEvent(_addItem, 'ItemAdded', {
            description: description,
            amount: toBN(10),
            price: price
        })


    })

    it('should NOT ORDER items above available amounts', async () => {
        await expectRevert(
            supplyChain.orderItem(
                identifier,
                12,
                { from: accounts[1], value: toWEI('12', 'ether') }
            ),
            'Not enough items left!'
        )
    })

    it('should NOT ORDER items if not full payment', async () => {
        await expectRevert(
            supplyChain.orderItem(
                identifier,
                5,
                { from: accounts[1], value: toWEI('1', 'ether'), gasPrice: 1 }
            ),
            'Only full payment accepted!'
        )

    })

    it('should ORDER item', async () => {
        const _orderitem = await supplyChain.orderItem(
            identifier,
            2,
            { from: accounts[1], value: toWEI('2', 'ether'), gasPrice: 1 }
        )

        expectEvent(_orderitem, 'ItemAvailable', {
            available: true,
            soldedAmount: toBN(2),
            availableAmount: toBN(8)
        })

        expectEvent(_orderitem, 'ItemOrderedBy', {
            buyer: accounts[1],
            itemId: identifier,
            orderedAmount: toBN(2),
            state: toBN(1)
        })
    })

    it('should NOT DELIVER item if not admin', async () => {
        await expectRevert(
            supplyChain.deliverItem(
                identifier,
                accounts[1],
                { from: accounts[2] }
            ),
            'Only owner!'
        )
    })

    it('should NOT DELIVER item if not in ORDERED state', async () => {
        await expectRevert(
            supplyChain.deliverItem(
                identifier,
                accounts[2]
            ),
            'Only ORDERED txs!'
        )
    })

    it('should DELIVER item', async () => {
        await supplyChain.deliverItem(
            identifier,
            accounts[1]
        )
        const tx = await supplyChain.deliveries(accounts[1], identifier)
        assert.equal(tx.numOfItems, '2')
        assert.equal(tx.state, '2')
    })

    it('should return balance of contract', async () => {
        const balance = await supplyChain.balanceOf()
        assert.equal(balance, (toWEI('2', 'ether')))
    })
})