describe('Test visit count api', () => {
    it('fetches visitorCounter', () => {
        cy.request('GET', `/1`)
            .then((resp) => {
                const data = resp.body;

                expect(resp.status).to.eq(200)

                expect(data.count).to.not.be.oneOf([null, "", undefined])
            })
    })
})
